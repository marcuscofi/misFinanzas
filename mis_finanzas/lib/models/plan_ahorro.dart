import 'package:cloud_firestore/cloud_firestore.dart';

enum ReglaAhorro { porcentaje, montoFijo }

class PlanAhorro {
  const PlanAhorro({
    this.id = '',
    required this.nombre,
    required this.regla,
    required this.valor,
    this.objetivoCentavos,
    required this.desde,
    this.hasta,
  });

  final String id;
  final String nombre;
  final ReglaAhorro regla;

  /// porcentaje: 1–100 (% de tus ingresos). montoFijo: centavos por mes.
  final int valor;

  /// Meta total opcional (ej. $1,200 para un viaje).
  final int? objetivoCentavos;
  final DateTime desde;

  /// null = plan activo. Con fecha = detenido (lo acumulado se conserva).
  final DateTime? hasta;

  bool get activo => hasta == null;

  factory PlanAhorro.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PlanAhorro(
      id: doc.id,
      nombre: d['nombre'] as String? ?? 'Plan',
      regla: ReglaAhorro.values.byName(d['regla'] as String),
      valor: (d['valor'] as num).toInt(),
      objetivoCentavos: (d['objetivoCentavos'] as num?)?.toInt(),
      desde: (d['desde'] as Timestamp).toDate(),
      hasta: (d['hasta'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'regla': regla.name,
        'valor': valor,
        'objetivoCentavos': objetivoCentavos,
        'desde': Timestamp.fromDate(desde),
        'hasta': hasta == null ? null : Timestamp.fromDate(hasta!),
      };
}