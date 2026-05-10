import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/medicine_model.dart';
import '../../../providers/app_providers.dart';
import '../models/medicine_models.dart';

// ── Model mapping ──────────────────────────────────────────────────────────────

MedicineComparison _toComparison(MedicineModel m) {
  final genericName = m.genericName.isNotEmpty ? m.genericName : m.name;
  final desc = m.description.isNotEmpty
      ? m.description
      : (m.hasDiscount
          ? '${m.discountPercent}% discount applied — same medicine at reduced price'
          : 'Generic equivalent available at standard price');
  return MedicineComparison(
    brandedName:          m.name,
    brandedMaker:         m.manufacturer,
    brandedForm:          m.displayForm.isNotEmpty ? m.displayForm : '–',
    brandedPriceRs:       m.priceBeforeRs,
    prescriptionRequired: m.prescriptionRequired,
    category:             m.category,
    genericName:          genericName,
    genericDesc:          desc,
    firstUsage:           m.usage.isNotEmpty ? m.usage.first : '',
    genericPriceRs:       m.priceAfterRs,
    savingsPercent:       m.discountPercent,
    pharmacyCount:        m.pharmacies.isNotEmpty ? m.pharmacies.length : 0,
    pharmacyNames:        m.pharmacies,
  );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class MedicineNotifier extends Notifier<MedicineState> {
  @override
  MedicineState build() => const MedicineState();

  Future<void> searchMedicine(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = state.copyWith(
          searchQuery: '', clearComparison: true, isSearching: false);
      return;
    }

    final recent = [
      q,
      ...state.recentSearches.where((s) => s.toLowerCase() != q.toLowerCase()),
    ].take(5).toList();

    state = state.copyWith(
      searchQuery: q,
      recentSearches: recent,
      isSearching: true,
      clearComparison: true,
    );

    try {
      final results =
          await ref.read(medicineRepositoryProvider).searchMedicines(q);
      if (results.isEmpty) {
        state = state.copyWith(isSearching: false, clearComparison: true);
      } else {
        state = state.copyWith(
          isSearching: false,
          comparison: _toComparison(results.first),
        );
      }
    } catch (_) {
      state = state.copyWith(isSearching: false, clearComparison: true);
    }
  }

  void selectRecent(String label) => searchMedicine(label);

  void toggleIncluded(String id) {
    final updated = state.scannedMedicines.map((m) {
      if (m.id == id) return m.copyWith(isIncluded: !m.isIncluded);
      return m;
    }).toList();
    state = state.copyWith(scannedMedicines: updated);
  }

  void editName(String id, String newName) {
    if (newName.trim().isEmpty) return;
    final updated = state.scannedMedicines.map((m) {
      if (m.id == id) return m.copyWith(name: newName.trim(), isUnclear: false);
      return m;
    }).toList();
    state = state.copyWith(scannedMedicines: updated);
  }

  void addManually(String name) {
    if (name.trim().isEmpty) return;
    final id = 'manual_${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(scannedMedicines: [
      ...state.scannedMedicines,
      ScannedMedicine(
        id: id,
        name: name.trim(),
        genericLabel: name.trim().toUpperCase(),
        isIncluded: true,
        isUnclear: false,
      ),
    ]);
  }

  /// HARDCODED: Returns demo scanned medicines. Replace with real Firebase lookup when ready.
  Future<void> loadScannedFromFirebase(List<String> names) async {
    if (names.isEmpty) {
      state = state.copyWith(scannedMedicines: []);
      return;
    }
    state = state.copyWith(isSearching: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      isSearching: false,
      scannedMedicines: [
        ScannedMedicine(
          id: 'mock_0',
          name: 'Augmentin 625mg',
          genericLabel: 'Amoxicillin + Clavulanic Acid · 625mg',
        ),
        ScannedMedicine(
          id: 'mock_1',
          name: 'Panadol 500mg',
          genericLabel: 'Paracetamol · 500mg',
        ),
        ScannedMedicine(
          id: 'mock_2',
          name: 'Omeprazole 20mg',
          genericLabel: 'Omeprazole · 20mg',
        ),
        ScannedMedicine(
          id: 'mock_3',
          name: 'Brufen 400mg',
          genericLabel: 'Ibuprofen · 400mg',
        ),
      ],
    );
  }

  /// Sets scanned medicines directly (e.g. names from OCR before Firebase lookup).
  void setScannedNames(List<String> names) {
    final medicines = names
        .asMap()
        .entries
        .map((e) => ScannedMedicine(
              id: '${e.key}',
              name: e.value,
              genericLabel: e.value.toUpperCase(),
              isIncluded: true,
              isUnclear: false,
            ))
        .toList();
    state = state.copyWith(scannedMedicines: medicines);
  }

  void toggleTorch() => state = state.copyWith(hasTorch: !state.hasTorch);
  void resetSearch() =>
      state = state.copyWith(searchQuery: '', clearComparison: true);
  void resetAll() => state = const MedicineState();
}

final medicineProvider =
    NotifierProvider<MedicineNotifier, MedicineState>(MedicineNotifier.new);
