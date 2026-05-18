import 'package:curo/features/medicines/models/medicine_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── ScannedMedicine ────────────────────────────────────────────────────────

  group('ScannedMedicine', () {
    test('defaults isIncluded to true and isUnclear to false', () {
      final m = ScannedMedicine(
        id: 'sm1',
        name: 'Panadol',
        genericLabel: 'Paracetamol',
      );
      expect(m.isIncluded, isTrue);
      expect(m.isUnclear, isFalse);
    });

    test('copyWith preserves id and frequency', () {
      final original = ScannedMedicine(
        id: 'sm1',
        name: 'Panadol',
        genericLabel: 'Paracetamol',
        frequency: 'Twice daily',
        isIncluded: true,
        isUnclear: false,
      );

      final copy = original.copyWith(isIncluded: false, isUnclear: true);

      expect(copy.id, 'sm1');
      expect(copy.frequency, 'Twice daily');
      expect(copy.isIncluded, isFalse);
      expect(copy.isUnclear, isTrue);
    });

    test('copyWith without arguments produces equal state', () {
      final m = ScannedMedicine(
        id: 'sm2',
        name: 'Augmentin',
        genericLabel: 'Amoxicillin',
        isIncluded: true,
      );
      final copy = m.copyWith();

      expect(copy.name, m.name);
      expect(copy.genericLabel, m.genericLabel);
      expect(copy.isIncluded, m.isIncluded);
    });

    test('copyWith updates name and clears unclear is independent of name', () {
      final m = ScannedMedicine(
        id: 'sm3',
        name: 'Brufn',
        genericLabel: 'Ibuprofen',
        isUnclear: true,
      );
      final corrected = m.copyWith(name: 'Brufen', isUnclear: false);

      expect(corrected.name, 'Brufen');
      expect(corrected.isUnclear, isFalse);
      expect(corrected.id, 'sm3');
    });
  });

  // ── MedicineComparison.priceDiffPercent ───────────────────────────────────

  group('MedicineComparison.priceDiffPercent', () {
    MedicineComparison make({int branded = 200, int generic = 100}) =>
        MedicineComparison(
          brandedName: 'Panadol',
          brandedMaker: 'GSK',
          brandedForm: '500mg · 10 Tabs',
          brandedPriceRs: branded,
          prescriptionRequired: false,
          category: 'tablet',
          genericName: 'Paracetamol',
          genericDesc: 'Pain reliever',
          firstUsage: 'Pain, Fever',
          genericPriceRs: generic,
          savingsPercent: 50,
          pharmacyCount: 3,
          pharmacyNames: ['MedCity'],
        );

    test('calculates correct percentage difference', () {
      // (200 - 100) / 200 * 100 = 50%
      expect(make(branded: 200, generic: 100).priceDiffPercent, 50);
    });

    test('rounds to nearest integer', () {
      // (300 - 100) / 300 * 100 = 66.66... → 67
      expect(make(branded: 300, generic: 100).priceDiffPercent, 67);
    });

    test('returns 0 when brandedPriceRs is 0 (avoid divide-by-zero)', () {
      expect(make(branded: 0, generic: 50).priceDiffPercent, 0);
    });

    test('returns 0 when prices are equal', () {
      expect(make(branded: 200, generic: 200).priceDiffPercent, 0);
    });

    test('returns negative when generic is more expensive', () {
      // (100 - 200) / 100 * 100 = -100%
      expect(make(branded: 100, generic: 200).priceDiffPercent, -100);
    });
  });

  // ── MedicineState ──────────────────────────────────────────────────────────

  group('MedicineState.includedCount and unclearCount', () {
    ScannedMedicine med(String id, {bool included = true, bool unclear = false}) =>
        ScannedMedicine(
          id: id,
          name: 'Med$id',
          genericLabel: 'Gen',
          isIncluded: included,
          isUnclear: unclear,
        );

    test('includedCount counts medicines with isIncluded = true', () {
      final state = MedicineState(scannedMedicines: [
        med('1', included: true),
        med('2', included: false),
        med('3', included: true),
      ]);
      expect(state.includedCount, 2);
    });

    test('unclearCount counts medicines with isUnclear = true', () {
      final state = MedicineState(scannedMedicines: [
        med('1', unclear: true),
        med('2', unclear: false),
        med('3', unclear: true),
        med('4', unclear: true),
      ]);
      expect(state.unclearCount, 3);
    });

    test('both counts are 0 for empty list', () {
      const state = MedicineState();
      expect(state.includedCount, 0);
      expect(state.unclearCount, 0);
    });
  });

  group('MedicineState.copyWith', () {
    test('clearComparison = true removes comparison', () {
      final comparison = MedicineComparison(
        brandedName: 'X', brandedMaker: 'M', brandedForm: 'F',
        brandedPriceRs: 100, prescriptionRequired: false,
        category: 'tablet', genericName: 'G', genericDesc: 'D',
        firstUsage: 'U', genericPriceRs: 50, savingsPercent: 50,
        pharmacyCount: 1, pharmacyNames: [],
      );
      final state = MedicineState(comparison: comparison);

      final cleared = state.copyWith(clearComparison: true);
      expect(cleared.comparison, isNull);
    });

    test('clearComparison = false keeps existing comparison', () {
      final comparison = MedicineComparison(
        brandedName: 'X', brandedMaker: 'M', brandedForm: 'F',
        brandedPriceRs: 100, prescriptionRequired: false,
        category: 'tablet', genericName: 'G', genericDesc: 'D',
        firstUsage: 'U', genericPriceRs: 50, savingsPercent: 50,
        pharmacyCount: 1, pharmacyNames: [],
      );
      final state = MedicineState(comparison: comparison);

      final kept = state.copyWith();
      expect(kept.comparison, isNotNull);
    });

    test('updates searchQuery and isSearching independently', () {
      const state = MedicineState();
      final updated = state.copyWith(searchQuery: 'Panadol', isSearching: true);

      expect(updated.searchQuery, 'Panadol');
      expect(updated.isSearching, isTrue);
      expect(updated.hasTorch, isFalse);
    });

    test('toggles hasTorch', () {
      const state = MedicineState(hasTorch: false);
      final toggled = state.copyWith(hasTorch: true);
      expect(toggled.hasTorch, isTrue);
    });
  });
}
