import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoTransaccion { ingreso, gasto }

const categoriasGasto = [
  'Comida', 'Transporte', 'Hogar', 'Salud', 'Ocio', 'Servicios', 'Otros',
];
const categoriasIngreso = ['Salario', 'Extra', 'Otros'];

class Transaccion {
  const Transaccion({
    this.id = '',
    required this.montoCentavos,
    required this.tipo,
    required this.categoria,
    this.descripcion = '',
    required this.fecha,
  });

  final String id;

  /// Entero en centavos: evita errores de redondeo de los double.
  final int montoCentavos;
  final TipoTransaccion tipo;
  final String categoria;
  final String descripcion;
  final DateTime fecha;

  double get monto => montoCentavos / 100;

  /// Positivo para ingresos, negativo para gastos.
  int get centavosConSigno =>
      tipo == TipoTransaccion.ingreso ? montoCentavos : -montoCentavos;

  factory Transaccion.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Transaccion(
      id: doc.id,
      montoCentavos: (d['montoCentavos'] as num).toInt(),
      tipo: TipoTransaccion.values.byName(d['tipo'] as String),
      categoria: d['categoria'] as String? ?? 'Otros',
      descripcion: d['descripcion'] as String? ?? '',
      fecha: (d['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'montoCentavos': montoCentavos,
        'tipo': tipo.name,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': Timestamp.fromDate(fecha),
      };
}