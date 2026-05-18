import 'package:curo/data/models/lab_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_snapshot.dart';

void main() {
  // ── fromFirestore ──────────────────────────────────────────────────────────

  group('LabModel.fromFirestore', () {
    test('parses all fields correctly', () {
      final doc = FakeDoc('lab_001', {
        'name': 'Chughtai Lab',
        'address': '12 Main Blvd, Lahore',
        'lat': 31.5204,
        'lng': 74.3587,
        'rating': 4.8,
        'reviewCount': 1200,
        'startingPriceRs': 500,
        'openingHours': 'Mon–Sat: 7AM–10PM',
        'city': 'Lahore',
        'area': 'Gulberg',
        'phone': '+924235765870',
        'website': 'https://chughtailab.com',
        'is24Hours': false,
        'tests': ['CBC', 'LFT', 'TSH'],
      });

      final lab = LabModel.fromFirestore(doc);

      expect(lab.id, 'lab_001');
      expect(lab.name, 'Chughtai Lab');
      expect(lab.lat, closeTo(31.5204, 0.0001));
      expect(lab.lng, closeTo(74.3587, 0.0001));
      expect(lab.rating, closeTo(4.8, 0.01));
      expect(lab.reviewCount, 1200);
      expect(lab.startingPriceRs, 500);
      expect(lab.city, 'Lahore');
      expect(lab.is24Hours, isFalse);
      expect(lab.tests, ['CBC', 'LFT', 'TSH']);
    });

    test('converts integer lat/lng to double', () {
      final doc = FakeDoc('lab_002', {
        'lat': 33,
        'lng': 73,
        'name': '', 'address': '', 'rating': 0, 'reviewCount': 0,
        'startingPriceRs': 0, 'openingHours': '',
      });

      final lab = LabModel.fromFirestore(doc);

      expect(lab.lat, isA<double>());
      expect(lab.lng, isA<double>());
    });

    test('uses defaults for missing optional fields', () {
      final doc = FakeDoc('lab_003', <String, dynamic>{
        'name': 'Minimal Lab',
        'address': 'Karachi',
        'lat': 24.0,
        'lng': 67.0,
        'rating': 3.0,
        'reviewCount': 10,
        'startingPriceRs': 200,
        'openingHours': '9AM–5PM',
      });

      final lab = LabModel.fromFirestore(doc);

      expect(lab.city, '');
      expect(lab.area, '');
      expect(lab.phone, '');
      expect(lab.website, '');
      expect(lab.is24Hours, isFalse);
      expect(lab.tests, isEmpty);
    });
  });

  // ── toFirestore ────────────────────────────────────────────────────────────

  group('LabModel.toFirestore', () {
    test('outputs all required keys', () {
      const lab = LabModel(
        id: 'lab_001',
        name: 'Test Lab',
        address: 'Karachi',
        lat: 24.86,
        lng: 67.01,
        rating: 4.5,
        reviewCount: 300,
        startingPriceRs: 800,
        openingHours: '8AM–8PM',
        city: 'Karachi',
        area: 'Clifton',
        tests: ['CBC'],
      );

      final map = lab.toFirestore();

      expect(map['name'], 'Test Lab');
      expect(map['lat'], 24.86);
      expect(map['lng'], 67.01);
      expect(map['rating'], 4.5);
      expect(map['startingPriceRs'], 800);
      expect(map['city'], 'Karachi');
      expect(map['tests'], ['CBC']);
    });

    test('roundtrip preserves data', () {
      const original = LabModel(
        id: 'lab_999',
        name: 'Roundtrip Lab',
        address: 'Islamabad',
        lat: 33.72,
        lng: 73.04,
        rating: 4.2,
        reviewCount: 500,
        startingPriceRs: 350,
        openingHours: '24hrs',
        city: 'Islamabad',
        is24Hours: true,
        tests: ['MRI', 'ECG'],
      );

      final map = original.toFirestore();
      final restored = LabModel.fromFirestore(
        FakeDoc('lab_999', map),
      );

      expect(restored.name, original.name);
      expect(restored.rating, original.rating);
      expect(restored.is24Hours, original.is24Hours);
      expect(restored.tests, original.tests);
    });
  });
}
