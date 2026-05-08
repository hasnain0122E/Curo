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

  /// Prefix search on medicine name (case-insensitive).
  Future<List<MedicineModel>> searchMedicines(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.trim().toLowerCase();
    final snap = await _medicines
        .where('nameLower', isGreaterThanOrEqualTo: lower)
        .where('nameLower', isLessThanOrEqualTo: '$lower')
        .limit(10)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Fetch medicines by exact name list (used after prescription scan).
  Future<List<MedicineModel>> getMedicinesByNames(List<String> names) async {
    if (names.isEmpty) return [];
    final lower = names.map((n) => n.trim().toLowerCase()).toList();
    final snap = await _medicines
        .where('nameLower', whereIn: lower.take(10).toList())
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
