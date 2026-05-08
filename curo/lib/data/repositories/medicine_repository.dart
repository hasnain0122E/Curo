import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';

class MedicineRepository {
  MedicineRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<MedicineModel> get _medicines => _firestore
      .collection('medicines')
      .withConverter<MedicineModel>(
        fromFirestore: (snap, _) => MedicineModel.fromFirestore(snap),
        toFirestore: (model, _) => model.toFirestore(),
      );

  Future<List<MedicineModel>> searchMedicines(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.trim().toLowerCase();
    // Append high-value char to create prefix upper bound for Firestore range query
    final upperBound = lower + String.fromCharCode(0xf8ff);
    final snap = await _medicines
        .where('nameLower', isGreaterThanOrEqualTo: lower)
        .where('nameLower', isLessThanOrEqualTo: upperBound)
        .limit(10)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<MedicineModel>> getMedicinesByNames(List<String> names) async {
    if (names.isEmpty) return [];
    final lower = names.map((n) => n.trim().toLowerCase()).toList();
    final snap = await _medicines
        .where('nameLower', whereIn: lower.take(10).toList())
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
