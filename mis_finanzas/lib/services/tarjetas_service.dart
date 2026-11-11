import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarjeta.dart';

class TarjetasService {
  TarjetasService(this.uid, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;
  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('tarjetas');

  Stream<List<Tarjeta>> observar() => _col
      .orderBy('creada')
      .snapshots()
      .map((s) => s.docs.map(Tarjeta.fromDoc).toList());

  // Sin await en la UI: offline estos Future no se completan hasta sincronizar.
  Future<void> guardar(Tarjeta t) =>
      (t.id.isEmpty ? _col.doc() : _col.doc(t.id)).set(t.toMap());

  Future<void> archivar(String id, {required bool activa}) =>
      _col.doc(id).update({'activa': activa});
}