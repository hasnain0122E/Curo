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

  /// Prefix search on brand name; returns up to 10 results.
  Future<List<MedicineModel>> searchMedicines(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.trim().toLowerCase();
    final upperBound = lower + String.fromCharCode(0xf8ff);
    final snap = await _medicines
        .where('nameLower', isGreaterThanOrEqualTo: lower)
        .where('nameLower', isLessThanOrEqualTo: upperBound)
        .limit(10)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Exact lookup by a list of lowercase medicine names (max 10).
  /// Used by OCR/Gemini results.
  Future<List<MedicineModel>> getMedicinesByNames(List<String> names) async {
    if (names.isEmpty) return [];
    final lower = names.map((n) => n.trim().toLowerCase()).toSet().toList();

    // Firestore whereIn is limited to 30 items; we already limit Gemini to 10.
    final snap = await _medicines
        .where('nameLower', whereIn: lower.take(10).toList())
        .get();

    final exact = snap.docs.map((d) => d.data()).toList();
    if (exact.isNotEmpty) return exact;

    // Fuzzy fallback: do prefix searches for each name individually.
    final results = <MedicineModel>[];
    final seen = <String>{};
    for (final name in lower.take(5)) {
      final hits = await searchMedicines(name);
      for (final m in hits) {
        if (seen.add(m.id)) results.add(m);
      }
      if (results.length >= 10) break;
    }
    return results;
  }
}
