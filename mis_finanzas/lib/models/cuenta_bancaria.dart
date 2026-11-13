import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/cifrado_service.dart';

enum TipoCuentaBancaria { cuenta, debito }

class CuentaBancaria {
  const CuentaBancaria({
    this.id = '',
    required this.banco,
    this.alias = '',
    this.tipo = TipoCuentaBancaria.cuenta,
    this.activa = true,
    required this.creada,
  });

  final String id;
  final String banco;
  final String alias;
  final TipoCuentaBancaria tipo;
  final bool activa;
  final DateTime creada;

  bool get esDebito => tipo == TipoCuentaBancaria.debito;
  String get bancoCorto => banco.replaceFirst('Banco ', '');
  String get tipoEtiqueta => esDebito ? 'Débito' : 'Cuenta';
  String get nombre => alias.trim().isEmpty
      ? '$bancoCorto · $tipoEtiqueta'
      : '$bancoCorto · ${alias.trim()}';

  factory CuentaBancaria.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CuentaBancaria(
      id: doc.id,
      banco: d['banco'] as String? ?? 'Otro',
      alias: CifradoService.descifrar(d['alias'] as String? ?? ''),
      tipo:
          TipoCuentaBancaria.values.asNameMap()[d['tipo'] as String?] ??
          TipoCuentaBancaria.cuenta,
      activa: d['activa'] as bool? ?? true,
      creada: (d['creada'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'banco': banco,
    'alias': CifradoService.cifrar(alias),
    'tipo': tipo.name,
    'activa': activa,
    'creada': Timestamp.fromDate(creada),
  };
}
