import 'package:curo/data/models/medicine_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_snapshot.dart';

void main() {
  MedicineModel make({
    int priceBefore = 100,
    int priceAfter = 80,
    int discount = 20,
    String strength = '500mg',
    String packSize = '10 Tabs',
  }) => MedicineModel(
    id: 'm1',
    name: 'Panadol',
    nameLower: 'panadol',
    genericName: 'Paracetamol',
    manufacturer: 'GSK',
    category: 'tablet',
    description: 'Pain reliever',
    strength: strength,
    packSize: packSize,
    available: true,
    inStock: true,
    prescriptionRequired: false,
    priceBeforeRs: priceBefore,
    priceAfterRs: priceAfter,
    discountPercent: discount,
    pharmacies: [],
    usage: [],
  );

  // ── hasDiscount ────────────────────────────────────────────────────────────

  group('MedicineModel.hasDiscount', () {
    test('true when discount > 0 and priceAfter < priceBefore', () {
      expect(make().hasDiscount, isTrue);
    });

    test('false when discountPercent is 0', () {
      expect(make(discount: 0, priceAfter: 80).hasDiscount, isFalse);
    });

    test('false when priceAfter equals priceBefore despite discount field', () {
      expect(
        make(discount: 10, priceAfter: 100, priceBefore: 100).hasDiscount,
        isFalse,
      );
    });

    test('false when priceAfter is greater than priceBefore', () {
      expect(
        make(discount: 5, priceAfter: 110, priceBefore: 100).hasDiscount,
        isFalse,
      );
    });
  });

  // ── displayForm ────────────────────────────────────────────────────────────

  group('MedicineModel.displayForm', () {
    test('joins strength and packSize with dot separator', () {
      expect(
        make(strength: '500mg', packSize: '10 Tabs').displayForm,
        '500mg · 10 Tabs',
      );
    });

    test('returns only strength when packSize is empty', () {
      expect(make(strength: '250mg', packSize: '').displayForm, '250mg');
    });

    test('returns only packSize when strength is empty', () {
      expect(make(strength: '', packSize: '30 Caps').displayForm, '30 Caps');
    });

    test('returns empty string when both are empty', () {
      expect(make(strength: '', packSize: '').displayForm, '');
    });
  });

  // ── fromFirestore ──────────────────────────────────────────────────────────

  group('MedicineModel.fromFirestore', () {
    test('parses all fields correctly', () {
      final doc = FakeDoc('med_001', {
        'name': 'Augmentin',
        'nameLower': 'augmentin',
        'genericName': 'Amoxicillin/Clavulanate',
        'manufacturer': 'GSK',
        'category': 'tablet',
        'description': 'Antibiotic',
        'strength': '625mg',
        'packSize': '10 Tabs',
        'available': true,
        'inStock': true,
        'prescriptionRequired': true,
        'priceBeforeRs': 450,
        'priceAfterRs': 400,
        'discountPercent': 11,
        'pharmacies': ['MedCity', 'Fazal Din'],
        'usage': ['Bacterial infections'],
        'city': 'Lahore',
        'country': 'Pakistan',
      });

      final m = MedicineModel.fromFirestore(doc);

      expect(m.id, 'med_001');
      expect(m.name, 'Augmentin');
      expect(m.genericName, 'Amoxicillin/Clavulanate');
      expect(m.strength, '625mg');
      expect(m.priceBeforeRs, 450);
      expect(m.priceAfterRs, 400);
      expect(m.prescriptionRequired, isTrue);
      expect(m.pharmacies, ['MedCity', 'Fazal Din']);
    });

    test('defaults priceAfterRs to priceBeforeRs when missing', () {
      final doc = FakeDoc('med_002', {
        'name': 'X',
        'nameLower': 'x',
        'genericName': '',
        'manufacturer': '',
        'category': 'tablet',
        'description': '',
        'strength': '',
        'packSize': '',
        'available': true,
        'inStock': true,
        'prescriptionRequired': false,
        'priceBeforeRs': 200,
        'discountPercent': 0,
        'pharmacies': [],
        'usage': [],
      });

      final m = MedicineModel.fromFirestore(doc);
      expect(m.priceAfterRs, 200);
    });

    test('converts num prices to int', () {
      final doc = FakeDoc('med_003', {
        'name': 'X',
        'nameLower': 'x',
        'genericName': '',
        'manufacturer': '',
        'category': 'tablet',
        'description': '',
        'strength': '',
        'packSize': '',
        'available': true,
        'inStock': true,
        'prescriptionRequired': false,
        'priceBeforeRs': 150.0,
        'priceAfterRs': 120.0,
        'discountPercent': 20.0,
        'pharmacies': [],
        'usage': [],
      });

      final m = MedicineModel.fromFirestore(doc);
      expect(m.priceBeforeRs, isA<int>());
      expect(m.priceAfterRs, isA<int>());
      expect(m.discountPercent, isA<int>());
    });
  });

  // ── toFirestore ────────────────────────────────────────────────────────────

  group('MedicineModel.toFirestore', () {
    test('adds genericNameLower derived field', () {
      // call via instance since make returns MedicineModel directly
      final med = MedicineModel(
        id: 'x',
        name: 'Panadol',
        nameLower: 'panadol',
        genericName: 'Paracetamol',
        manufacturer: 'GSK',
        category: 'tablet',
        description: '',
        strength: '',
        packSize: '',
        available: true,
        inStock: true,
        prescriptionRequired: false,
        priceBeforeRs: 100,
        priceAfterRs: 80,
        discountPercent: 20,
        pharmacies: [],
        usage: [],
      );

      final firestoreMap = med.toFirestore();

      expect(firestoreMap['genericNameLower'], 'paracetamol');
      expect(firestoreMap['nameLower'], 'panadol');
    });
  });
}
