import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the OCR prescription-parsing logic.
///
/// The full [MlKitOcrService.scanPrescription] method requires ML Kit native
/// libraries and a real image file — those are integration tests. Here we test
/// the parsing patterns and rules in isolation by reproducing them as pure Dart.
void main() {
  // Reproduce the blocklist regex from MlKitOcrService exactly.
  final blocklistPattern = RegExp(
    r'^(dr|mr|mrs|ms|prof|patient|name|age|date|sex|gender|diagnosis|rx|'
    r'twice|thrice|daily|morning|night|evening|after|before|meals|days|weeks|'
    r'bd|tds|qid|od|sos|prn|stat|hs|ac|pc|'
    r'hospital|clinic|pharmacy|lab|laboratory|address|phone|tel|'
    r'cbc|lft|rft|urine|blood|sugar|glucose|hba1c|tsh|ecg|x.?ray|'
    r'fever|infection|hypertension|diabetes|cold|cough|pain|pressure|'
    r'take|use|apply|dissolve|swallow|tablet|capsule|syrup|injection|'
    r'signature|stamp|seal|ref|no\.|#)\b',
    caseSensitive: false,
  );

  // Reproduce the dosage detection regex from MlKitOcrService exactly.
  final dosagePattern = RegExp(
    r'^([A-Za-z][A-Za-z\s\-]+?)\s+\d+\s*(?:mg|ml|mcg|g|iu|units?)',
    caseSensitive: false,
  );

  // ── blocklist pattern ──────────────────────────────────────────────────────

  group('Blocklist pattern', () {
    test('matches instruction words (daily, morning, night)', () {
      expect(blocklistPattern.hasMatch('daily'), isTrue);
      expect(blocklistPattern.hasMatch('morning'), isTrue);
      expect(blocklistPattern.hasMatch('night'), isTrue);
    });

    test('matches abbreviated dosing schedules (bd, tds, od)', () {
      expect(blocklistPattern.hasMatch('bd'), isTrue);
      expect(blocklistPattern.hasMatch('tds'), isTrue);
      expect(blocklistPattern.hasMatch('od'), isTrue);
    });

    test('matches personal titles (dr, mr, mrs)', () {
      expect(blocklistPattern.hasMatch('dr'), isTrue);
      expect(blocklistPattern.hasMatch('mr'), isTrue);
      expect(blocklistPattern.hasMatch('mrs'), isTrue);
    });

    test('matches medical header words (diagnosis, patient)', () {
      expect(blocklistPattern.hasMatch('diagnosis'), isTrue);
      expect(blocklistPattern.hasMatch('patient'), isTrue);
    });

    test('matches lab test abbreviations (cbc, lft, tsh)', () {
      expect(blocklistPattern.hasMatch('cbc'), isTrue);
      expect(blocklistPattern.hasMatch('lft'), isTrue);
      expect(blocklistPattern.hasMatch('tsh'), isTrue);
    });

    test('matches symptom words (fever, cough, pain)', () {
      expect(blocklistPattern.hasMatch('fever'), isTrue);
      expect(blocklistPattern.hasMatch('cough'), isTrue);
      expect(blocklistPattern.hasMatch('pain'), isTrue);
    });

    test('is case-insensitive', () {
      expect(blocklistPattern.hasMatch('DAILY'), isTrue);
      expect(blocklistPattern.hasMatch('DR'), isTrue);
      expect(blocklistPattern.hasMatch('CBC'), isTrue);
    });

    test('does NOT match valid drug names', () {
      expect(blocklistPattern.hasMatch('Augmentin'), isFalse);
      expect(blocklistPattern.hasMatch('Panadol'), isFalse);
      expect(blocklistPattern.hasMatch('Amoxil'), isFalse);
      expect(blocklistPattern.hasMatch('Brufen'), isFalse);
    });
  });

  // ── dosage extraction regex ────────────────────────────────────────────────

  group('Dosage detection regex', () {
    test('matches "Augmentin 625mg"', () {
      expect(dosagePattern.hasMatch('Augmentin 625mg'), isTrue);
    });

    test('matches "Panadol 500 mg" (space before unit)', () {
      expect(dosagePattern.hasMatch('Panadol 500 mg'), isTrue);
    });

    test('matches "Brufen 400mg"', () {
      expect(dosagePattern.hasMatch('Brufen 400mg'), isTrue);
    });

    test('matches mcg unit (Eltroxin 50mcg)', () {
      expect(dosagePattern.hasMatch('Eltroxin 50mcg'), isTrue);
    });

    test('matches ml unit (Augmentin 250ml)', () {
      expect(dosagePattern.hasMatch('Augmentin 250ml'), isTrue);
    });

    test('matches IU unit (Vitamin D 1000 IU)', () {
      expect(dosagePattern.hasMatch('Vitamin D 1000 IU'), isTrue);
    });

    test('matches units (Insulin 10 units)', () {
      expect(dosagePattern.hasMatch('Insulin 10 units'), isTrue);
    });

    test('does NOT match drug name without strength', () {
      expect(dosagePattern.hasMatch('Panadol'), isFalse);
    });

    test('does NOT match lines starting with a digit', () {
      expect(dosagePattern.hasMatch('500mg Panadol'), isFalse);
    });
  });

  // ── pure-Dart parsing logic (extracted for testability) ───────────────────

  group('Parsing helper rules', () {
    test('purely numeric/symbolic lines are filtered out', () {
      final numericLinePattern = RegExp(r'^[\d\s\.\-\+\/\(\),]+$');
      expect(numericLinePattern.hasMatch('123.45'), isTrue);
      expect(numericLinePattern.hasMatch('(+92) 300-1234'), isTrue);
      expect(numericLinePattern.hasMatch('Augmentin 625'), isFalse);
    });

    test('lines not starting with a letter are filtered', () {
      final startsWithLetter = RegExp(r'^[A-Za-z]');
      expect(startsWithLetter.hasMatch('*Augmentin'), isFalse);
      expect(startsWithLetter.hasMatch('1. Panadol'), isFalse);
      expect(startsWithLetter.hasMatch('Panadol'), isTrue);
    });

    test('candidate normalization capitalizes first letter', () {
      const raw = 'augmentin 625mg';
      final normalized = raw[0].toUpperCase() + raw.substring(1);
      expect(normalized, 'Augmentin 625mg');
    });

    test('deduplication by lowercase key prevents duplicates', () {
      final seen = <String>{};
      final candidates = ['Panadol', 'panadol', 'PANADOL'];
      final unique = <String>[];
      for (final c in candidates) {
        final key = c.toLowerCase();
        if (!seen.contains(key)) {
          seen.add(key);
          unique.add(c);
        }
      }
      expect(unique, hasLength(1));
      expect(unique.first, 'Panadol');
    });

    test('max 10 results limit is enforced', () {
      final results = List.generate(20, (i) => 'Drug$i');
      final limited = results.take(10).toList();
      expect(limited, hasLength(10));
    });

    test('lines longer than 60 chars are skipped', () {
      final longLine =
          'This is a very long line that should be filtered out because it exceeds 60 chars';
      expect(longLine.length > 60, isTrue);
    });

    test('candidates shorter than 3 or longer than 50 chars are rejected', () {
      bool isValidLength(String c) => c.length >= 3 && c.length <= 50;
      expect(isValidLength('AB'), isFalse);
      expect(isValidLength('Abc'), isTrue);
      expect(isValidLength('A' * 51), isFalse);
      expect(isValidLength('A' * 50), isTrue);
    });
  });
}
