import 'package:cloud_firestore/cloud_firestore.dart';

const bancos = [
  'Banco Agrícola', 'Banco Cuscatlán', 'Davivienda', 'BAC Credomatic',
  'Banco Promerica', 'Banco Hipotecario', 'Banco Industrial', 'Banco Azul',
  'Otro',
];

class Tarjeta {
  const Tarjeta({
    this.id = '',
    required this.banco,
    this.alias = '',
    required this.limiteMensualCentavos,
    this.activa = true,
    required this.creada,
  });

  final String id;
  final String banco;
  final String alias;

  /// Presupuesto mensual de la tarjeta: se renueva el día 1 de cada mes.
  final int limiteMensualCentavos;
  final bool activa;
  final DateTime creada;

  String get bancoCorto => banco.replaceFirst('Banco ', '');
  String get nombre => alias.trim().isEmpty ? bancoCorto : '$bancoCorto · ${alias.trim()}';

  factory Tarjeta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Tarjeta(
      id: doc.id,
      banco: d['banco'] as String? ?? 'Otro',
      alias: d['alias'] as String? ?? '',
      limiteMensualCentavos: (d['limiteMensualCentavos'] as num).toInt(),
      activa: d['activa'] as bool? ?? true,
      creada: (d['creada'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'banco': banco,
        'alias': alias,
        'limiteMensualCentavos': limiteMensualCentavos,
        'activa': activa,
        'creada': Timestamp.fromDate(creada),
      };
}