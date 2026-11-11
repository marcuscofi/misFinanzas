import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/models/estado_mascota.dart';
import 'package:mis_finanzas/models/transaccion.dart';
import 'package:mis_finanzas/utils/analisis.dart';

Transaccion g(int c, DateTime f) => Transaccion(
    montoCentavos: c, tipo: TipoTransaccion.gasto, categoria: 'Comida', fecha: f);
Transaccion i(int c, DateTime f) => Transaccion(
    montoCentavos: c, tipo: TipoTransaccion.ingreso, categoria: 'Salario', fecha: f);

void main() {
  final ahora = DateTime(2026, 11, 10);

  test('separa periodo actual y anterior (7 días)', () {
    final r = analizar([
      g(1000, DateTime(2026, 11, 10)),
      g(200, DateTime(2026, 11, 4)),
      g(500, DateTime(2026, 11, 3)), // periodo anterior
      g(999, DateTime(2026, 10, 27)), // fuera de ambos
    ], const Periodo.dias(7), ahora);
    expect(r.gastos, 1200);
    expect(r.gastosPrevios, 500);
    expect(r.serie.length, 7);
    expect(r.serie.first, 200);
    expect(r.serie.last, 1000);
    expect(r.variacion, closeTo(1.4, 1e-9));
  });

  test('variación es null sin periodo previo', () {
    final r = analizar([g(100, ahora)], const Periodo.dias(7), ahora);
    expect(r.variacion, isNull);
  });

  test('mascota: balance negativo es pánico', () {
    final r = analizar([g(100, ahora)], const Periodo.dias(7), ahora);
    expect(evaluarMascota(balance: -1, r: r, hayDatos: true).estado,
        EstadoMascota.panico);
  });

  test('mascota: gasta más de lo que ingresa suda', () {
    final r = analizar(
        [i(1000, ahora), g(5000, ahora)], const Periodo.dias(7), ahora);
    expect(evaluarMascota(balance: 3000, r: r, hayDatos: true).estado,
        EstadoMascota.sudando);
  });

  test('mascota: ahorra el 90 % celebra', () {
    final r = analizar([
      i(100000, DateTime(2026, 11, 5)),
      g(10000, DateTime(2026, 11, 6)),
    ], const Periodo.dias(7), ahora);
    expect(evaluarMascota(balance: 90000, r: r, hayDatos: true).estado,
        EstadoMascota.celebra);
  });

  test('reacción al monto: gasto enorme alarma', () {
    expect(
        reaccionAlMonto(tipo: TipoTransaccion.gasto, centavos: 9000, balance: 10000)
            .estado,
        EstadoMascota.sudando);
  });
}