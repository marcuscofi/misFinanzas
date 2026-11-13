import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/models/cuenta_bancaria.dart';
import 'package:mis_finanzas/models/tarjeta.dart';
import 'package:mis_finanzas/models/transaccion.dart';
import 'package:mis_finanzas/services/cifrado_service.dart';
import 'package:mis_finanzas/utils/presupuesto.dart';

Transaccion mov(int c, TipoTransaccion tipo, String cuenta, DateTime f) =>
    Transaccion(
      montoCentavos: c,
      tipo: tipo,
      categoria: tipo == TipoTransaccion.ingreso ? 'Salario' : 'Comida',
      fecha: f,
      cuentaId: cuenta,
    );

void main() {
  final fecha = DateTime(2026, 11, 10);
  final cuenta = CuentaBancaria(
    id: 'cuenta-1',
    banco: 'Banco Agrícola',
    alias: 'Nómina',
    creada: fecha,
  );

  setUpAll(() {
    CifradoService.configurarLlave(
      'clave-de-pruebas-con-longitud-suficiente-para-aes-256',
    );
  });

  group('saldos de cuentas bancarias', () {
    test('suma ingresos y resta gastos asociados', () {
      final movs = [
        mov(100000, TipoTransaccion.ingreso, 'cuenta-1', fecha),
        mov(25000, TipoTransaccion.gasto, 'cuenta-1', fecha),
        mov(9000, TipoTransaccion.gasto, cuentaEfectivo, fecha),
        mov(5000, TipoTransaccion.gasto, 'tarjeta-1', fecha),
      ];
      expect(calcularSaldoCuenta(movs, 'cuenta-1'), 75000);
      expect(calcularBalanceEfectivo(movs), -9000);
      expect(calcularLiquidoTotal(movs, [cuenta]), 66000);
    });

    test('cuenta sin movimientos tiene saldo cero', () {
      expect(calcularSaldoCuenta([], 'cuenta-1'), 0);
      expect(calcularLiquidoTotal([], [cuenta]), 0);
    });
  });

  group('presupuesto semanal con cuentas', () {
    test('incluye el saldo de las cuentas en lo disponible', () {
      final movs = [
        mov(100000, TipoTransaccion.ingreso, 'cuenta-1', fecha),
        mov(20000, TipoTransaccion.gasto, 'cuenta-1', fecha),
      ];
      final s = calcularSemana(
        movs: movs,
        tarjetas: const [],
        planes: const [],
        ahora: fecha,
        cuentasBancarias: [cuenta],
      );
      expect(s.cuentasRestante, 80000);
      expect(s.disponible, 80000);
      expect(s.gastado, 20000);
      expect(s.asignacionOptimista, 50000);
      expect(s.asignacionPesimista, 35000);
      expect(s.quedanOptimista, 30000);
      expect(s.quedanPesimista, 15000);
    });

    test('calcula los bloques de semanas que quedan del mes', () {
      final medioMes = calcularSemana(
        movs: const [],
        tarjetas: const [],
        planes: const [],
        ahora: DateTime(2026, 11, 10),
      );
      expect(medioMes.semanasRestantesEnteras, 2);
      expect(medioMes.semanasExactas, closeTo(20 / 7, 1e-9));

      final ultimosDias = calcularSemana(
        movs: const [],
        tarjetas: const [],
        planes: const [],
        ahora: DateTime(2026, 11, 24),
      );
      expect(ultimosDias.semanasRestantesEnteras, 1);
      expect(ultimosDias.semanasExactas, 1.0);
    });

    test('16 días restantes separa escenario optimista y pesimista', () {
      final ahora = DateTime(2026, 11, 14);
      final movs = [
        mov(
          1000000,
          TipoTransaccion.ingreso,
          cuentaEfectivo,
          DateTime(2026, 11, 1),
        ),
      ];
      final s = calcularSemana(
        movs: movs,
        tarjetas: const [],
        planes: const [],
        ahora: ahora,
      );
      expect(s.diasRestantesEnMes, 16);
      expect(s.semanasRestantesEnteras, 2);
      expect(s.semanasExactas, closeTo(16 / 7, 1e-9));
      expect(s.asignacionOptimista, 500000);
      expect(s.asignacionPesimista, 437500);
      expect(s.quedanOptimista, 500000);
      expect(s.quedanPesimista, 437500);
      expect(s.quedanPesimista, lessThan(s.quedanOptimista));
    });
  });

  group('cifrado E2EE', () {
    test('cifra y descifra con AES-256 y IV aleatorio', () {
      const claro = 'Cena con amigos';
      final primero = CifradoService.cifrar(claro);
      final segundo = CifradoService.cifrar(claro);

      expect(primero, isNot(claro));
      expect(primero, startsWith('e2ee:v1:'));
      expect(segundo, isNot(primero));
      expect(CifradoService.descifrar(primero), claro);
      expect(CifradoService.descifrar(segundo), claro);
    });

    test('devuelve texto plano antiguo sin lanzar excepciones', () {
      expect(CifradoService.descifrar('texto sin cifrar'), 'texto sin cifrar');
      expect(CifradoService.descifrar(''), '');
    });

    test('devuelve el valor original si el cifrado está corrupto', () {
      const corrupto = 'e2ee:v1:esto-no-es-base64';
      expect(CifradoService.descifrar(corrupto), corrupto);
    });

    test('cifra descripciones y alias en toMap sin tocar los montos', () {
      final transaccion = Transaccion(
        montoCentavos: 12345,
        tipo: TipoTransaccion.gasto,
        categoria: 'Comida',
        descripcion: 'Supermercado',
        fecha: fecha,
      );
      final mapTransaccion = transaccion.toMap();
      expect(mapTransaccion['descripcion'], startsWith('e2ee:v1:'));
      expect(
        CifradoService.descifrar(mapTransaccion['descripcion'] as String),
        'Supermercado',
      );
      expect(mapTransaccion['montoCentavos'], 12345);

      final mapCuenta = cuenta.toMap();
      expect(mapCuenta['alias'], startsWith('e2ee:v1:'));
      expect(CifradoService.descifrar(mapCuenta['alias'] as String), 'Nómina');

      final tarjeta = Tarjeta(
        id: 'tarjeta-1',
        banco: 'BAC Credomatic',
        alias: 'Visa Oro',
        limiteMensualCentavos: 50000,
        creada: fecha,
      );
      final mapTarjeta = tarjeta.toMap();
      expect(mapTarjeta['alias'], startsWith('e2ee:v1:'));
      expect(
        CifradoService.descifrar(mapTarjeta['alias'] as String),
        'Visa Oro',
      );
      expect(mapTarjeta['limiteMensualCentavos'], 50000);
    });
  });
}
