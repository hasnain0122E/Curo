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
  /// Used by OCR/Gemini results. Also tries genericNameLower for generic names.
  Future<List<MedicineModel>> getMedicinesByNames(List<String> names) async {
    if (names.isEmpty) return [];
    final lower = names.map((n) => n.trim().toLowerCase()).toSet().toList();
    final batch = lower.take(10).toList();

    // Try brand name first
    final byBrand = await _medicines.where('nameLower', whereIn: batch).get();
    final results = <String, MedicineModel>{};
    for (final d in byBrand.docs) {
      results[d.id] = d.data();
    }

    // Try generic name for any still unmatched
    final foundNames = results.values.map((m) => m.nameLower).toSet();
    final unmatched = batch.where((n) => !foundNames.contains(n)).toList();
    if (unmatched.isNotEmpty) {
      final byGeneric = await _medicines
          .where('genericNameLower', whereIn: unmatched)
          .get();
      for (final d in byGeneric.docs) {
        results.putIfAbsent(d.id, () => d.data());
      }
    }

    if (results.isNotEmpty) return results.values.toList();

    // Fuzzy fallback: prefix search for each name individually.
    final fuzzy = <MedicineModel>[];
    final seen = <String>{};
    for (final name in batch.take(5)) {
      for (final m in await searchMedicines(name)) {
        if (seen.add(m.id)) {
          fuzzy.add(m);
        }
      }
      if (fuzzy.length >= 10) break;
    }
    return fuzzy;
  }
}
