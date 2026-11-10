import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaccion.dart';

class TransaccionesService {
  TransaccionesService(this.uid, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('transacciones');

  /// Stream en tiempo real; también emite desde la caché local sin red.
  Stream<List<Transaccion>> observar({int limite = 200}) {
    return _col
        .orderBy('fecha', descending: true)
        .limit(limite)
        .snapshots()
        .map((s) => s.docs.map(Transaccion.fromDoc).toList());
  }

  /// OJO: sin conexión este Future NO se completa hasta que el servidor
  /// confirma. En la UI no uses `await`: el stream ya refleja el cambio
  /// local al instante.
  Future<void> agregar(Transaccion t) => _col.doc().set(t.toMap());

  Future<void> actualizar(Transaccion t) => _col.doc(t.id).update(t.toMap());

  Future<void> eliminar(String id) => _col.doc(id).delete();
}