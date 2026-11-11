import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoTransaccion { ingreso, gasto }

/// Id reservado de la "cuenta" efectivo. Las tarjetas usan su id de Firestore.
const cuentaEfectivo = 'efectivo';

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
    this.cuentaId = cuentaEfectivo,
  });

  final String id;
  final int montoCentavos;
  final TipoTransaccion tipo;
  final String categoria;
  final String descripcion;
  final DateTime fecha;

  /// 'efectivo' o el id de una tarjeta. Los ingresos siempre son 'efectivo'.
  final String cuentaId;

  bool get afectaEfectivo => cuentaId == cuentaEfectivo;
  double get monto => montoCentavos / 100;

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
      cuentaId: d['cuentaId'] as String? ?? cuentaEfectivo, // docs viejos
    );
  }

  Map<String, dynamic> toMap() => {
        'montoCentavos': montoCentavos,
        'tipo': tipo.name,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': Timestamp.fromDate(fecha),
        'cuentaId': cuentaId,
      };
}