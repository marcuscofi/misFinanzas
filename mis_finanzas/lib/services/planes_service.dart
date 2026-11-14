import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plan_ahorro.dart';

class PlanesService {
  PlanesService(this.uid, {FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('planesAhorro');

  Stream<List<PlanAhorro>> observar() => _col
      .orderBy('desde')
      .snapshots()
      .map((s) => s.docs.map(PlanAhorro.fromDoc).toList());

  Future<void> guardar(PlanAhorro p) =>
      (p.id.isEmpty ? _col.doc() : _col.doc(p.id)).set(p.toMap());

  /// Deja de acumular; lo ya ahorrado se conserva.
  Future<void> detener(String id) =>
      _col.doc(id).update({'hasta': Timestamp.now()});

  /// Borra el plan y libera lo acumulado al dinero disponible.
  Future<void> eliminar(String id) => _col.doc(id).delete();
}
