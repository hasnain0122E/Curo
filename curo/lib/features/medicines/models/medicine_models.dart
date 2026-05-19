/// A cost-effective market alternative for a given generic molecule,
/// sourced from Firebase or the static Pakistani-market lookup table.
class GenericAlternative {
  const GenericAlternative({
    required this.brandName,
    required this.genericFormula,
    required this.form,
    required this.priceRs,
    required this.manufacturer,
    this.savingNote = '',
  });

  final String brandName;
  final String genericFormula;
  final String form;
  final int priceRs;
  final String manufacturer;
  final String savingNote;
}

// ── Scanned medicine entry ─────────────────────────────────────────────────────

class ScannedMedicine {
  ScannedMedicine({
    required this.id,
    required this.name,
    required this.genericLabel,
    this.frequency,
    this.genericFormula = '',
    this.dosage = '',
    this.form = '',
    this.alternatives = const [],
    this.isIncluded = true,
    this.isUnclear = false,
  });

  final String id;
  final String name;
  final String genericLabel;
  final String? frequency;
  final String genericFormula;
  final String dosage;
  final String form;
  final List<GenericAlternative> alternatives;
  bool isIncluded;
  bool isUnclear;

  ScannedMedicine copyWith({
    String? name,
    String? genericLabel,
    bool? isIncluded,
    bool? isUnclear,
    List<GenericAlternative>? alternatives,
  }) =>
      ScannedMedicine(
        id: id,
        name: name ?? this.name,
        genericLabel: genericLabel ?? this.genericLabel,
        frequency: frequency,
        genericFormula: genericFormula,
        dosage: dosage,
        form: form,
        alternatives: alternatives ?? this.alternatives,
        isIncluded: isIncluded ?? this.isIncluded,
        isUnclear: isUnclear ?? this.isUnclear,
      );
}

// ── Medicine comparison (search finder) ───────────────────────────────────────

class MedicineComparison {
  const MedicineComparison({
    required this.brandedName,
    required this.brandedMaker,
    required this.brandedForm,
    required this.brandedPriceRs,
    required this.prescriptionRequired,
    required this.category,
    required this.genericName,
    required this.genericDesc,
    required this.firstUsage,
    required this.genericPriceRs,
    required this.savingsPercent,
    required this.pharmacyCount,
    required this.pharmacyNames,
  });

  final String brandedName;
  final String brandedMaker;
  final String brandedForm;
  final int brandedPriceRs;
  final bool prescriptionRequired;
  final String category;
  final String genericName;
  final String genericDesc;
  final String firstUsage;
  final int genericPriceRs;
  final int savingsPercent;
  final int pharmacyCount;
  final List<String> pharmacyNames;

  int get priceDiffPercent => brandedPriceRs > 0
      ? (((brandedPriceRs - genericPriceRs) / brandedPriceRs) * 100).round()
      : 0;
}

// ── Provider state ─────────────────────────────────────────────────────────────

class MedicineState {
  const MedicineState({
    this.scannedMedicines = const [],
    this.comparison,
    this.recentSearches = const ['Panadol', 'Augmentin', 'Brufen', 'Amoxil'],
    this.searchQuery = '',
    this.hasTorch = false,
    this.isSearching = false,
  });

  final List<ScannedMedicine> scannedMedicines;
  final MedicineComparison? comparison;
  final List<String> recentSearches;
  final String searchQuery;
  final bool hasTorch;
  final bool isSearching;

  int get includedCount => scannedMedicines.where((m) => m.isIncluded).length;
  int get unclearCount => scannedMedicines.where((m) => m.isUnclear).length;

  MedicineState copyWith({
    List<ScannedMedicine>? scannedMedicines,
    MedicineComparison? comparison,
    bool clearComparison = false,
    List<String>? recentSearches,
    String? searchQuery,
    bool? hasTorch,
    bool? isSearching,
  }) =>
      MedicineState(
        scannedMedicines: scannedMedicines ?? this.scannedMedicines,
        comparison: clearComparison ? null : (comparison ?? this.comparison),
        recentSearches: recentSearches ?? this.recentSearches,
        searchQuery: searchQuery ?? this.searchQuery,
        hasTorch: hasTorch ?? this.hasTorch,
        isSearching: isSearching ?? this.isSearching,
      );
}
