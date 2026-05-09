import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/medicine_model.dart';
import '../../../providers/app_providers.dart';
import '../models/medicine_models.dart';

// ── Model mapping ──────────────────────────────────────────────────────────────

MedicineComparison _toComparison(MedicineModel m) {
  final hasDiscount = m.hasDiscount;
  return MedicineComparison(
    brandedName: m.name,
    brandedMaker: m.manufacturer,
    brandedForm: m.packSize.isNotEmpty ? m.packSize : '–',
    brandedPriceRs: m.priceBeforeRs,
    genericName: m.name,
    genericDesc: hasDiscount
        ? '${m.discountPercent}% discount applied\nSame medicine at reduced price'
        : 'Standard price\nNo discount currently available',
    genericPriceRs: m.priceAfterRs,
    savingsPercent: m.discountPercent,
    pharmacyCount: 10 + (m.name.codeUnitAt(0) % 15),
  );
}

List<ScannedMedicine> _buildScanned(List<MedicineModel> models) =>
    models.asMap().entries.map((e) {
      final m = e.value;
      return ScannedMedicine(
        id: '${e.key}',
        name: m.name,
        genericLabel: '${m.name.toUpperCase()} · ${m.packSize}',
        isIncluded: true,
        isUnclear: false,
      );
    }).toList();

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

  /// Loads scanned medicines from Firebase lookup by name.
  /// Shows empty list (not mock data) when Firebase returns nothing.
  Future<void> loadScannedFromFirebase(List<String> names) async {
    if (names.isEmpty) {
      state = state.copyWith(scannedMedicines: []);
      return;
    }
    state = state.copyWith(isSearching: true);
    try {
      final results =
          await ref.read(medicineRepositoryProvider).getMedicinesByNames(names);
      state = state.copyWith(
        isSearching: false,
        scannedMedicines: _buildScanned(results),
      );
    } catch (_) {
      state = state.copyWith(isSearching: false, scannedMedicines: []);
    }
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
