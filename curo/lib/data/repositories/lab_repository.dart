import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lab_model.dart';

class LabRepository {
  LabRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<LabModel> get _labs => _firestore
      .collection('labs')
      .withConverter<LabModel>(
        fromFirestore: (snap, _) => LabModel.fromFirestore(snap),
        toFirestore: (model, _) => model.toFirestore(),
      );

  Stream<List<LabModel>> watchLabs() {
    return _labs
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<List<LabModel>> getLabsNearby({int limit = 20}) async {
    final snap = await _labs
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<LabModel?> getLabById(String labId) async {
    final doc = await _labs.doc(labId).get();
    return doc.data();
  }
}
