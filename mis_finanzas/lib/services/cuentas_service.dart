import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cuenta_bancaria.dart';

class CuentasBancariasService {
  CuentasBancariasService(this.uid, {FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('cuentasBancarias');

  Stream<List<CuentaBancaria>> snapshots() => _col
      .orderBy('creada')
      .snapshots()
      .map((s) => s.docs.map(CuentaBancaria.fromDoc).toList());

  Stream<List<CuentaBancaria>> observar() => snapshots();

  // Sin await en la UI: offline estos Future no se completan hasta sincronizar.
  Future<void> guardar(CuentaBancaria c) =>
      (c.id.isEmpty ? _col.doc() : _col.doc(c.id)).set(c.toMap());

  Future<void> archivar(String id, {required bool activa}) =>
      _col.doc(id).update({'activa': activa});

  Future<void> eliminar(String id) => _col.doc(id).delete();
}
