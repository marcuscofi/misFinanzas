import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/models/cuenta_bancaria.dart';
import 'package:mis_finanzas/models/transaccion.dart';
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
      expect(s.asignacion, 100000 ~/ s.semanasRestantes);
    });
  });
}
