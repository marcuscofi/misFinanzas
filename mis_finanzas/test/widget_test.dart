import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/models/transaccion.dart';
import 'package:mis_finanzas/utils/formato.dart';

void main() {
  group('formatoUsd', () {
    test('formatea centavos como dólares', () {
      expect(formatoUsd(1250), r'$12.50');
      expect(formatoUsd(-500), r'-$5.00');
      expect(formatoUsd(123456), r'$1,234.56');
    });
  });

  group('parseCentavos', () {
    test('acepta punto y coma decimal', () {
      expect(parseCentavos('12.5'), 1250);
      expect(parseCentavos('12,50'), 1250);
      expect(parseCentavos('7'), 700);
    });
    test('rechaza entradas inválidas', () {
      expect(parseCentavos(''), isNull);
      expect(parseCentavos('abc'), isNull);
      expect(parseCentavos('1.234'), isNull);
      expect(parseCentavos('-5'), isNull);
    });
  });

  group('Transaccion', () {
    test('centavosConSigno distingue ingresos y gastos', () {
      final ingreso = Transaccion(
        montoCentavos: 1000,
        tipo: TipoTransaccion.ingreso,
        categoria: 'Salario',
        fecha: DateTime(2026, 1, 1),
      );
      final gasto = Transaccion(
        montoCentavos: 400,
        tipo: TipoTransaccion.gasto,
        categoria: 'Comida',
        fecha: DateTime(2026, 1, 1),
      );
      expect(ingreso.centavosConSigno, 1000);
      expect(gasto.centavosConSigno, -400);
    });
  });
}
