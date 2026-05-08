class ScannedMedicine {
  ScannedMedicine({
    required this.id,
    required this.name,
    required this.genericLabel,
    this.frequency,
    this.isIncluded = true,
    this.isUnclear = false,
  });

  final String id;
  final String name;
  final String genericLabel;
  final String? frequency;
  bool isIncluded;
  bool isUnclear;

  ScannedMedicine copyWith({
    String? name,
    String? genericLabel,
    bool? isIncluded,
    bool? isUnclear,
  }) =>
      ScannedMedicine(
        id: id,
        name: name ?? this.name,
        genericLabel: genericLabel ?? this.genericLabel,
        frequency: frequency,
        isIncluded: isIncluded ?? this.isIncluded,
        isUnclear: isUnclear ?? this.isUnclear,
      );
}

class MedicineComparison {
  const MedicineComparison({
    required this.brandedName,
    required this.brandedMaker,
    required this.brandedForm,
    required this.brandedPriceRs,
    required this.genericName,
    required this.genericDesc,
    required this.genericPriceRs,
    required this.savingsPercent,
    required this.pharmacyCount,
  });

  final String brandedName;
  final String brandedMaker;
  final String brandedForm;
  final int brandedPriceRs;
  final String genericName;
  final String genericDesc;
  final int genericPriceRs;
  final int savingsPercent;
  final int pharmacyCount;

  int get priceDiffPercent =>
      (((brandedPriceRs - genericPriceRs) / brandedPriceRs) * 100).round();
}

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
        comparison:
            clearComparison ? null : (comparison ?? this.comparison),
        recentSearches: recentSearches ?? this.recentSearches,
        searchQuery: searchQuery ?? this.searchQuery,
        hasTorch: hasTorch ?? this.hasTorch,
        isSearching: isSearching ?? this.isSearching,
      );
}
