import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import '../models/transaccion.dart';
import 'cifrado_service.dart';

/// true solo en builds de prueba: --dart-define=MODO_PRUEBAS=true
const modoPruebas = bool.fromEnvironment('MODO_PRUEBAS') && !kReleaseMode;

class LoteTransacciones {
  const LoteTransacciones(
    this.items, {
    this.pendientes = false,
    this.desdeCache = false,
  });
  final List<Transaccion> items;

  /// Hay escrituras locales aún no confirmadas por el servidor.
  final bool pendientes;

  /// El snapshot viene de la caché (sin conexión o aún cargando).
  final bool desdeCache;
}

class TransaccionesService {
  TransaccionesService(this.uid, {FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;
  static const prefijoPrueba = '[test]';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('transacciones');

  Stream<LoteTransacciones> observar({int limite = 2000}) => _col
      .orderBy('fecha', descending: true)
      .limit(limite)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => LoteTransacciones(
          s.docs.map(Transaccion.fromDoc).toList(),
          pendientes: s.metadata.hasPendingWrites,
          desdeCache: s.metadata.isFromCache,
        ),
      );

  // Sin conexión estos Future no se completan hasta sincronizar: no usar await en la UI.
  Future<void> agregar(Transaccion t) => _col.doc().set(t.toMap());
  Future<void> actualizar(Transaccion t) => _col.doc(t.id).update(t.toMap());
  Future<void> eliminar(String id) => _col.doc(id).delete();

  // ---- Solo para pruebas (se muestran con MODO_PRUEBAS=true) ----

  void _exigirModoPruebas() {
    if (!modoPruebas) {
      throw StateError('MODO_PRUEBAS está desactivado en esta compilación.');
    }
  }

  Future<void> generarPrueba(int n) {
    _exigirModoPruebas();
    if (n < 1 || n > 500) {
      throw ArgumentError.value(n, 'n', 'Debe estar entre 1 y 500');
    }
    final batch = _db.batch();
    final rnd = Random();
    final ahora = DateTime.now();
    for (var i = 0; i < n; i++) {
      final ingreso = i % 5 == 0;
      final cats = ingreso ? categoriasIngreso : categoriasGasto;
      batch.set(
        _col.doc(),
        Transaccion(
          montoCentavos: 100 + rnd.nextInt(9900),
          tipo: ingreso ? TipoTransaccion.ingreso : TipoTransaccion.gasto,
          categoria: cats[rnd.nextInt(cats.length)],
          descripcion: '$prefijoPrueba #$i',
          fecha: ahora.subtract(Duration(days: rnd.nextInt(60))),
        ).toMap(),
      );
    }
    return batch.commit();
  }

  Future<void> borrarPrueba() async {
    _exigirModoPruebas();
    // Source.cache: funciona igual con o sin red.
    final s = await _col.get(const GetOptions(source: Source.cache));
    final batch = _db.batch();
    for (final d in s.docs) {
      final descripcion = CifradoService.descifrar(
        d.data()['descripcion'] as String? ?? '',
      );
      if (descripcion.startsWith(prefijoPrueba)) {
        batch.delete(d.reference);
      }
    }
    return batch.commit();
  }
}
