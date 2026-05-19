import 'dart:io';

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
    brandedName: m.name,
    brandedMaker: m.manufacturer,
    brandedForm: m.displayForm.isNotEmpty ? m.displayForm : '–',
    brandedPriceRs: m.priceBeforeRs,
    prescriptionRequired: m.prescriptionRequired,
    category: m.category,
    genericName: genericName,
    genericDesc: desc,
    firstUsage: m.usage.isNotEmpty ? m.usage.first : '',
    genericPriceRs: m.priceAfterRs,
    savingsPercent: m.discountPercent,
    pharmacyCount: m.pharmacies.isNotEmpty ? m.pharmacies.length : 0,
    pharmacyNames: m.pharmacies,
  );
}

// ── Static Pakistani market alternatives ──────────────────────────────────────
// Keyed by lowercase generic formula. Sorted longest-key-first at lookup time
// so "amoxicillin + clavulanic acid" wins over bare "amoxicillin".

const _pkAlternatives = <String, List<GenericAlternative>>{
  'amoxicillin + clavulanic acid': [
    GenericAlternative(
      brandName: 'Co-Amoxiclav',
      genericFormula: 'Amoxicillin + Clavulanic Acid',
      form: 'Tablet',
      priceRs: 420,
      manufacturer: 'Hilton Pharma',
      savingNote: '38% cheaper',
    ),
    GenericAlternative(
      brandName: 'Clavulin',
      genericFormula: 'Amoxicillin + Clavulanic Acid',
      form: 'Tablet',
      priceRs: 580,
      manufacturer: 'Roche Pakistan',
    ),
    GenericAlternative(
      brandName: 'Augmentin',
      genericFormula: 'Amoxicillin + Clavulanic Acid',
      form: 'Tablet',
      priceRs: 680,
      manufacturer: 'GSK Pakistan',
    ),
  ],
  'paracetamol': [
    GenericAlternative(
      brandName: 'Calpol',
      genericFormula: 'Paracetamol',
      form: 'Tablet',
      priceRs: 60,
      manufacturer: 'GSK Pakistan',
      savingNote: '8% cheaper',
    ),
    GenericAlternative(
      brandName: 'Tempra',
      genericFormula: 'Paracetamol',
      form: 'Tablet',
      priceRs: 52,
      manufacturer: 'Pfizer Pakistan',
      savingNote: '20% cheaper',
    ),
    GenericAlternative(
      brandName: 'Panadol',
      genericFormula: 'Paracetamol',
      form: 'Tablet',
      priceRs: 65,
      manufacturer: 'GSK Pakistan',
    ),
  ],
  'omeprazole': [
    GenericAlternative(
      brandName: 'Proton',
      genericFormula: 'Omeprazole',
      form: 'Capsule',
      priceRs: 80,
      manufacturer: 'Barrett Hodgson',
      savingNote: '27% cheaper',
    ),
    GenericAlternative(
      brandName: 'Lomac',
      genericFormula: 'Omeprazole',
      form: 'Capsule',
      priceRs: 95,
      manufacturer: 'Sami Pharma',
    ),
    GenericAlternative(
      brandName: 'Risek',
      genericFormula: 'Omeprazole',
      form: 'Capsule',
      priceRs: 110,
      manufacturer: 'AGP Ltd',
    ),
  ],
  'ibuprofen': [
    GenericAlternative(
      brandName: 'Profen',
      genericFormula: 'Ibuprofen',
      form: 'Tablet',
      priceRs: 60,
      manufacturer: 'Sami Pharma',
      savingNote: '29% cheaper',
    ),
    GenericAlternative(
      brandName: 'Brufen',
      genericFormula: 'Ibuprofen',
      form: 'Tablet',
      priceRs: 85,
      manufacturer: 'Abbott Pakistan',
    ),
    GenericAlternative(
      brandName: 'Nurofen',
      genericFormula: 'Ibuprofen',
      form: 'Tablet',
      priceRs: 95,
      manufacturer: 'Reckitt',
    ),
  ],
  'amoxicillin': [
    GenericAlternative(
      brandName: 'Amoxicillin',
      genericFormula: 'Amoxicillin',
      form: 'Capsule',
      priceRs: 90,
      manufacturer: 'Pharmedic',
      savingNote: '36% cheaper',
    ),
    GenericAlternative(
      brandName: 'Flemoxin',
      genericFormula: 'Amoxicillin',
      form: 'Tablet',
      priceRs: 120,
      manufacturer: 'Astellas',
    ),
    GenericAlternative(
      brandName: 'Amoxil',
      genericFormula: 'Amoxicillin',
      form: 'Capsule',
      priceRs: 140,
      manufacturer: 'GSK Pakistan',
    ),
  ],
  'metformin': [
    GenericAlternative(
      brandName: 'Dia-Tab',
      genericFormula: 'Metformin',
      form: 'Tablet',
      priceRs: 95,
      manufacturer: 'Bosch Pharma',
      savingNote: '55% cheaper',
    ),
    GenericAlternative(
      brandName: 'Metforal',
      genericFormula: 'Metformin',
      form: 'Tablet',
      priceRs: 130,
      manufacturer: 'Sanofi',
      savingNote: '38% cheaper',
    ),
    GenericAlternative(
      brandName: 'Glucophage',
      genericFormula: 'Metformin',
      form: 'Tablet',
      priceRs: 210,
      manufacturer: 'Merck Pakistan',
    ),
  ],
  'atorvastatin': [
    GenericAlternative(
      brandName: 'Ator',
      genericFormula: 'Atorvastatin',
      form: 'Tablet',
      priceRs: 180,
      manufacturer: 'PharmEvo',
      savingNote: '54% cheaper',
    ),
    GenericAlternative(
      brandName: 'Atocor',
      genericFormula: 'Atorvastatin',
      form: 'Tablet',
      priceRs: 220,
      manufacturer: 'Searle Pakistan',
      savingNote: '44% cheaper',
    ),
    GenericAlternative(
      brandName: 'Lipitor',
      genericFormula: 'Atorvastatin',
      form: 'Tablet',
      priceRs: 390,
      manufacturer: 'Pfizer Pakistan',
    ),
  ],
  'ciprofloxacin': [
    GenericAlternative(
      brandName: 'Ciplox',
      genericFormula: 'Ciprofloxacin',
      form: 'Tablet',
      priceRs: 190,
      manufacturer: 'Cipla',
      savingNote: '32% cheaper',
    ),
    GenericAlternative(
      brandName: 'Cipro',
      genericFormula: 'Ciprofloxacin',
      form: 'Tablet',
      priceRs: 210,
      manufacturer: 'Bayer Pakistan',
      savingNote: '25% cheaper',
    ),
    GenericAlternative(
      brandName: 'Cifran',
      genericFormula: 'Ciprofloxacin',
      form: 'Tablet',
      priceRs: 280,
      manufacturer: 'Ranbaxy',
    ),
  ],
  'azithromycin': [
    GenericAlternative(
      brandName: 'Azimax',
      genericFormula: 'Azithromycin',
      form: 'Tablet',
      priceRs: 250,
      manufacturer: 'Searle Pakistan',
      savingNote: '46% cheaper',
    ),
    GenericAlternative(
      brandName: 'Azithral',
      genericFormula: 'Azithromycin',
      form: 'Tablet',
      priceRs: 280,
      manufacturer: 'Alkem',
      savingNote: '39% cheaper',
    ),
    GenericAlternative(
      brandName: 'Zithromax',
      genericFormula: 'Azithromycin',
      form: 'Tablet',
      priceRs: 460,
      manufacturer: 'Pfizer Pakistan',
    ),
  ],
  'pantoprazole': [
    GenericAlternative(
      brandName: 'Panzo',
      genericFormula: 'Pantoprazole',
      form: 'Tablet',
      priceRs: 85,
      manufacturer: 'Barrett Hodgson',
      savingNote: '41% cheaper',
    ),
    GenericAlternative(
      brandName: 'Pantop',
      genericFormula: 'Pantoprazole',
      form: 'Tablet',
      priceRs: 98,
      manufacturer: 'Aristo Pharma',
      savingNote: '32% cheaper',
    ),
    GenericAlternative(
      brandName: 'Pantoloc',
      genericFormula: 'Pantoprazole',
      form: 'Tablet',
      priceRs: 145,
      manufacturer: 'Altana Pharma',
    ),
  ],
  'cefixime': [
    GenericAlternative(
      brandName: 'Zifi',
      genericFormula: 'Cefixime',
      form: 'Tablet',
      priceRs: 180,
      manufacturer: 'FDC',
      savingNote: '44% cheaper',
    ),
    GenericAlternative(
      brandName: 'Cefi',
      genericFormula: 'Cefixime',
      form: 'Tablet',
      priceRs: 210,
      manufacturer: 'Sami Pharma',
      savingNote: '34% cheaper',
    ),
    GenericAlternative(
      brandName: 'Suprax',
      genericFormula: 'Cefixime',
      form: 'Tablet',
      priceRs: 320,
      manufacturer: 'Pfizer Pakistan',
    ),
  ],
  'metronidazole': [
    GenericAlternative(
      brandName: 'Aldezol',
      genericFormula: 'Metronidazole',
      form: 'Tablet',
      priceRs: 48,
      manufacturer: 'Zafa Pharma',
      savingNote: '47% cheaper',
    ),
    GenericAlternative(
      brandName: 'Metrozine',
      genericFormula: 'Metronidazole',
      form: 'Tablet',
      priceRs: 55,
      manufacturer: 'ICI Pakistan',
      savingNote: '39% cheaper',
    ),
    GenericAlternative(
      brandName: 'Flagyl',
      genericFormula: 'Metronidazole',
      form: 'Tablet',
      priceRs: 90,
      manufacturer: 'Sanofi Pakistan',
    ),
  ],
  'diclofenac': [
    GenericAlternative(
      brandName: 'Diclowin',
      genericFormula: 'Diclofenac',
      form: 'Tablet',
      priceRs: 65,
      manufacturer: 'Win-Medicare',
      savingNote: '46% cheaper',
    ),
    GenericAlternative(
      brandName: 'Difene',
      genericFormula: 'Diclofenac',
      form: 'Tablet',
      priceRs: 75,
      manufacturer: 'Searle Pakistan',
      savingNote: '38% cheaper',
    ),
    GenericAlternative(
      brandName: 'Voltaren',
      genericFormula: 'Diclofenac',
      form: 'Tablet',
      priceRs: 120,
      manufacturer: 'Novartis Pakistan',
    ),
  ],
  'doxycycline': [
    GenericAlternative(
      brandName: 'Doxicip',
      genericFormula: 'Doxycycline',
      form: 'Capsule',
      priceRs: 140,
      manufacturer: 'Cipla',
      savingNote: '31% cheaper',
    ),
    GenericAlternative(
      brandName: 'Vibramycin',
      genericFormula: 'Doxycycline',
      form: 'Capsule',
      priceRs: 200,
      manufacturer: 'Pfizer Pakistan',
    ),
  ],
};

// ── Notifier ───────────────────────────────────────────────────────────────────

class MedicineNotifier extends Notifier<MedicineState> {
  @override
  MedicineState build() => const MedicineState();

  // ── Search (medicine finder) ─────────────────────────────────────────────────

  Future<void> searchMedicine(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        clearComparison: true,
        isSearching: false,
      );
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
      final results = await ref
          .read(medicineRepositoryProvider)
          .searchMedicines(q);
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

  // ── Scan result entry points ─────────────────────────────────────────────────

  /// Processes Groq's `medications` array from [analyzeMedicinePrescription].
  /// For each entry, resolves cost-effective alternatives (Firebase → static map)
  /// and populates [scannedMedicines].
  Future<void> loadFromGroqResult(
    List<Map<String, dynamic>> medications,
  ) async {
    if (medications.isEmpty) {
      state = state.copyWith(scannedMedicines: []);
      return;
    }

    state = state.copyWith(isSearching: true);

    final built = <ScannedMedicine>[];

    for (int i = 0; i < medications.length; i++) {
      final m = medications[i];
      final brandName = (m['brand_name'] as String? ?? '').trim();
      final genericFormula = (m['generic_formula'] as String? ?? '').trim();
      final dosage = (m['dosage'] as String? ?? '').trim();
      final form = (m['form'] as String? ?? '').trim();

      if (brandName.isEmpty && genericFormula.isEmpty) continue;

      final displayName = [
        brandName,
        dosage,
      ].where((s) => s.isNotEmpty).join(' ');
      final labelParts = [
        genericFormula,
        dosage,
      ].where((s) => s.isNotEmpty).join(' · ');

      final alternatives = await _getCostEffectiveAlternatives(genericFormula);

      built.add(
        ScannedMedicine(
          id: 'rx_$i',
          name: displayName.isNotEmpty ? displayName : genericFormula,
          genericLabel: labelParts,
          genericFormula: genericFormula,
          dosage: dosage,
          form: form,
          alternatives: alternatives,
          isIncluded: true,
          isUnclear: brandName.isEmpty,
        ),
      );
    }

    state = state.copyWith(isSearching: false, scannedMedicines: built);
  }

  /// Legacy entry point kept for backward compatibility (manual add flow).
  Future<void> loadScannedFromFirebase(List<String> names) async {
    if (names.isEmpty) {
      state = state.copyWith(scannedMedicines: []);
      return;
    }
    state = state.copyWith(isSearching: true);
    try {
      final results = await ref
          .read(medicineRepositoryProvider)
          .getMedicinesByNames(names.map((n) => n.toLowerCase()).toList());
      if (results.isEmpty) {
        state = state.copyWith(isSearching: false, scannedMedicines: []);
        return;
      }
      final medicines = results.asMap().entries.map((e) {
        final m = e.value;
        return ScannedMedicine(
          id: 'fb_${e.key}',
          name: m.name,
          genericLabel: m.genericName.isNotEmpty
              ? '${m.genericName} · ${m.strength}'
              : m.name,
          genericFormula: m.genericName,
          isIncluded: true,
          isUnclear: false,
        );
      }).toList();
      state = state.copyWith(isSearching: false, scannedMedicines: medicines);
    } catch (_) {
      state = state.copyWith(isSearching: false, scannedMedicines: []);
    }
  }

  // ── Scanned list mutations ────────────────────────────────────────────────────

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
    state = state.copyWith(
      scannedMedicines: [
        ...state.scannedMedicines,
        ScannedMedicine(
          id: id,
          name: name.trim(),
          genericLabel: name.trim().toUpperCase(),
          isIncluded: true,
          isUnclear: false,
        ),
      ],
    );
  }

  void setScannedNames(List<String> names) {
    final medicines = names
        .asMap()
        .entries
        .map(
          (e) => ScannedMedicine(
            id: '${e.key}',
            name: e.value,
            genericLabel: e.value.toUpperCase(),
            isIncluded: true,
            isUnclear: false,
          ),
        )
        .toList();
    state = state.copyWith(scannedMedicines: medicines);
  }

  void toggleTorch() => state = state.copyWith(hasTorch: !state.hasTorch);
  void resetSearch() =>
      state = state.copyWith(searchQuery: '', clearComparison: true);
  void resetAll() => state = const MedicineState();

  // ── Cost-effective alternative lookup ─────────────────────────────────────────

  /// Returns up to 3–4 affordable alternatives for [genericFormula].
  ///
  /// Strategy:
  ///   1. Firebase: `getMedicinesByNames([genericFormula])` — finds by brand OR
  ///      generic name index (`genericNameLower`).
  ///   2. Static map: `_pkAlternatives` keyed by lowercase generic molecule.
  ///      Longest key is tested first so "amoxicillin + clavulanic acid" wins
  ///      over bare "amoxicillin".
  Future<List<GenericAlternative>> _getCostEffectiveAlternatives(
    String genericFormula,
  ) async {
    final normalized = genericFormula.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    // Step 1: Firebase live lookup
    try {
      final results = await ref
          .read(medicineRepositoryProvider)
          .getMedicinesByNames([normalized]);
      if (results.isNotEmpty) {
        return results
            .take(4)
            .map(
              (m) => GenericAlternative(
                brandName: m.name,
                genericFormula: m.genericName.isNotEmpty
                    ? m.genericName
                    : genericFormula,
                form: m.category,
                priceRs: m.priceAfterRs,
                manufacturer: m.manufacturer,
                savingNote: m.hasDiscount ? '${m.discountPercent}% off' : '',
              ),
            )
            .toList();
      }
    } on SocketException {
      // Network drop — fall through to static map
    } catch (_) {}

    // Step 2: Static Pakistani-market fallback
    final sortedKeys = _pkAlternatives.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      if (normalized.contains(key) || key.contains(normalized)) {
        return _pkAlternatives[key]!;
      }
    }

    return [];
  }
}

final medicineProvider = NotifierProvider<MedicineNotifier, MedicineState>(
  MedicineNotifier.new,
);
