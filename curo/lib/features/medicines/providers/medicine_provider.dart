import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_models.dart';

const _kMockDb = <String, MedicineComparison>{
  'augmentin': MedicineComparison(
    brandedName: 'Augmentin 625mg',
    brandedMaker: 'GlaxoSmithKline (GSK)',
    brandedForm: '625mg • Tablet',
    brandedPriceRs: 850,
    genericName: 'Amoxicillin + Clavulanic Acid',
    genericDesc:
        'Therapeutically equivalent to branded version\nQuality Certified Bio-Equivalent',
    genericPriceRs: 295,
    savingsPercent: 65,
    pharmacyCount: 12,
  ),
  'panadol': MedicineComparison(
    brandedName: 'Panadol 500mg',
    brandedMaker: 'Haleon (GSK Consumer)',
    brandedForm: '500mg • Tablet',
    brandedPriceRs: 120,
    genericName: 'Paracetamol',
    genericDesc:
        'Therapeutically equivalent to branded version\nWidely available Bio-Equivalent',
    genericPriceRs: 35,
    savingsPercent: 71,
    pharmacyCount: 24,
  ),
  'ibuprofen': MedicineComparison(
    brandedName: 'Brufen 400mg',
    brandedMaker: 'Abbott Laboratories',
    brandedForm: '400mg • Tablet',
    brandedPriceRs: 180,
    genericName: 'Ibuprofen',
    genericDesc:
        'Therapeutically equivalent to branded version\nQuality Certified Bio-Equivalent',
    genericPriceRs: 55,
    savingsPercent: 69,
    pharmacyCount: 18,
  ),
  'amoxil': MedicineComparison(
    brandedName: 'Amoxil 500mg',
    brandedMaker: 'GlaxoSmithKline (GSK)',
    brandedForm: '500mg • Capsule',
    brandedPriceRs: 320,
    genericName: 'Amoxicillin',
    genericDesc:
        'Therapeutically equivalent to branded version\nQuality Certified Bio-Equivalent',
    genericPriceRs: 85,
    savingsPercent: 73,
    pharmacyCount: 20,
  ),
};

List<ScannedMedicine> _buildMockScanned() => [
      ScannedMedicine(
        id: '1',
        name: 'Amoxicillin 500mg',
        genericLabel: 'AMOXICILLIN CAP 500MG',
        frequency: '3x daily',
        isIncluded: true,
        isUnclear: false,
      ),
      ScannedMedicine(
        id: '2',
        name: 'Lisinopril 10mg',
        genericLabel: 'LISINOPRIL TAB 10MG (UNCLEAR)',
        frequency: '1x daily',
        isIncluded: true,
        isUnclear: true,
      ),
      ScannedMedicine(
        id: '3',
        name: 'Metformin 850mg',
        genericLabel: 'METFORMIN HCL 850MG',
        frequency: '2x daily',
        isIncluded: true,
        isUnclear: false,
      ),
      ScannedMedicine(
        id: '4',
        name: 'Atorvastatin 20mg',
        genericLabel: 'ATORVASTATIN CALC 20MG',
        frequency: '1x daily',
        isIncluded: true,
        isUnclear: false,
      ),
      ScannedMedicine(
        id: '5',
        name: 'Omeprazole 20mg',
        genericLabel: 'OMEPRAZ TAB 20MG DELAYED',
        frequency: '1x daily',
        isIncluded: true,
        isUnclear: true,
      ),
    ];

class MedicineNotifier extends Notifier<MedicineState> {
  @override
  MedicineState build() => const MedicineState();

  void loadMockScanResults() {
    state = state.copyWith(scannedMedicines: _buildMockScanned());
  }

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
      if (m.id == id) {
        return m.copyWith(name: newName.trim(), isUnclear: false);
      }
      return m;
    }).toList();
    state = state.copyWith(scannedMedicines: updated);
  }

  void addManually(String name) {
    if (name.trim().isEmpty) return;
    final id = 'manual_${DateTime.now().millisecondsSinceEpoch}';
    final medicine = ScannedMedicine(
      id: id,
      name: name.trim(),
      genericLabel: name.trim().toUpperCase(),
      isIncluded: true,
      isUnclear: false,
    );
    state = state.copyWith(
      scannedMedicines: [...state.scannedMedicines, medicine],
    );
  }

  void searchMedicine(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      state = state.copyWith(searchQuery: '', clearComparison: true);
      return;
    }
    final key = q.toLowerCase();
    MedicineComparison? match = _kMockDb[key];
    if (match == null) {
      for (final entry in _kMockDb.entries) {
        if (entry.key.contains(key) || key.contains(entry.key)) {
          match = entry.value;
          break;
        }
      }
    }
    final recent = [
      q,
      ...state.recentSearches.where((s) => s.toLowerCase() != key),
    ].take(5).toList();

    state = state.copyWith(
      searchQuery: query,
      comparison: match,
      recentSearches: recent,
      clearComparison: match == null,
    );
  }

  void selectRecent(String label) => searchMedicine(label);

  void toggleTorch() => state = state.copyWith(hasTorch: !state.hasTorch);

  void resetSearch() =>
      state = state.copyWith(searchQuery: '', clearComparison: true);

  void resetAll() => state = const MedicineState();
}

final medicineProvider =
    NotifierProvider<MedicineNotifier, MedicineState>(MedicineNotifier.new);
