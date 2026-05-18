import 'package:curo/core/widgets/status_chip.dart';
import 'package:curo/features/reports/models/health_locker_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── ReportCategoryX.label ─────────────────────────────────────────────────

  group('ReportCategoryX.label', () {
    test('all → "All"', () => expect(ReportCategory.all.label, 'All'));
    test('blood → "Blood"', () => expect(ReportCategory.blood.label, 'Blood'));
    test('urine → "Urine"', () => expect(ReportCategory.urine.label, 'Urine'));
    test('xray → "X-Ray"', () => expect(ReportCategory.xray.label, 'X-Ray'));
    test('ecg → "ECG"', () => expect(ReportCategory.ecg.label, 'ECG'));
    test('other → "Other"', () => expect(ReportCategory.other.label, 'Other'));
  });

  // ── LockerReport construction ──────────────────────────────────────────────

  group('LockerReport', () {
    test('stores all fields correctly', () {
      final report = LockerReport(
        id: 'r1',
        name: 'CBC Report',
        date: '10 May 2024',
        category: ReportCategory.blood,
        statusLabel: 'Normal',
        status: StatusVariant.success,
        icon: Icons.bloodtype_outlined,
        iconColor: Colors.red,
      );

      expect(report.id, 'r1');
      expect(report.name, 'CBC Report');
      expect(report.date, '10 May 2024');
      expect(report.category, ReportCategory.blood);
      expect(report.statusLabel, 'Normal');
      expect(report.status, StatusVariant.success);
      expect(report.icon, Icons.bloodtype_outlined);
      expect(report.iconColor, Colors.red);
    });

    test('two separately constructed instances are not the same object', () {
      LockerReport make() => LockerReport(
            id: 'r1',
            name: 'A',
            date: 'd',
            category: ReportCategory.other,
            statusLabel: 'X',
            status: StatusVariant.warning,
            icon: Icons.description,
            iconColor: Colors.grey,
          );

      expect(identical(make(), make()), isFalse);
    });
  });

  // ── StatusVariant enum ─────────────────────────────────────────────────────

  group('StatusVariant', () {
    test('has exactly 4 variants', () {
      expect(StatusVariant.values, hasLength(4));
    });

    test('contains success, warning, danger, medipoints', () {
      expect(StatusVariant.values, containsAll([
        StatusVariant.success,
        StatusVariant.warning,
        StatusVariant.danger,
        StatusVariant.medipoints,
      ]));
    });

    test('all values are distinct', () {
      final set = StatusVariant.values.toSet();
      expect(set.length, StatusVariant.values.length);
    });
  });

  // ── ReportCategory enum ────────────────────────────────────────────────────

  group('ReportCategory', () {
    test('has exactly 6 categories', () {
      expect(ReportCategory.values, hasLength(6));
    });
  });
}
