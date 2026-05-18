import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curo/data/models/report_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_snapshot.dart';

void main() {
  final uploadedAt = DateTime(2024, 5, 10);

  Map<String, dynamic> baseData({
    dynamic analysisJson,
    String? aiSummary,
  }) =>
      {
        'userId': 'user_1',
        'name': 'CBC Report',
        'category': 'Blood Test',
        'storageUrl': 'https://res.cloudinary.com/demo/cbc.pdf',
        'cloudinaryPublicId': 'curo_reports/user_1/abc123',
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        ?'aiSummary': aiSummary,
        ?'analysisJson': analysisJson,
      };

  // ── fromFirestore – analysisJson parsing ───────────────────────────────────

  group('ReportModel.fromFirestore analysisJson', () {
    test('parses analysisJson when stored as a JSON string', () {
      final jsonStr = jsonEncode({'results': [], 'summary': 'All normal'});
      final doc = FakeDoc('r1', baseData(analysisJson: jsonStr));

      final report = ReportModel.fromFirestore(doc);

      expect(report.analysisJson, isA<Map<String, dynamic>>());
      expect(report.analysisJson!['summary'], 'All normal');
    });

    test('passes through analysisJson when already a Map', () {
      final map = {'results': [], 'summary': 'Review needed'};
      final doc = FakeDoc('r2', baseData(analysisJson: map));

      final report = ReportModel.fromFirestore(doc);

      expect(report.analysisJson, isA<Map<String, dynamic>>());
      expect(report.analysisJson!['summary'], 'Review needed');
    });

    test('sets analysisJson to null when field is absent', () {
      final doc = FakeDoc('r3', baseData());

      final report = ReportModel.fromFirestore(doc);

      expect(report.analysisJson, isNull);
    });
  });

  // ── fromFirestore – general fields ────────────────────────────────────────

  group('ReportModel.fromFirestore fields', () {
    test('parses standard fields correctly', () {
      final doc = FakeDoc(
        'r_full',
        baseData(aiSummary: 'Haemoglobin slightly low.'),
      );

      final report = ReportModel.fromFirestore(doc);

      expect(report.id, 'r_full');
      expect(report.userId, 'user_1');
      expect(report.name, 'CBC Report');
      expect(report.category, 'Blood Test');
      expect(report.storageUrl, contains('cloudinary.com'));
      expect(report.cloudinaryPublicId, 'curo_reports/user_1/abc123');
      expect(report.aiSummary, 'Haemoglobin slightly low.');
      expect(report.uploadedAt, uploadedAt);
    });

    test('defaults category to Other when missing', () {
      final data = Map<String, dynamic>.from(baseData())..remove('category');
      final report = ReportModel.fromFirestore(FakeDoc('r_cat', data));
      expect(report.category, 'Other');
    });
  });

  // ── toFirestore ────────────────────────────────────────────────────────────

  group('ReportModel.toFirestore', () {
    test('excludes optional fields when null', () {
      final report = ReportModel(
        id: 'r1',
        userId: 'u1',
        name: 'Test',
        category: 'Other',
        storageUrl: 'https://example.com/r.pdf',
        uploadedAt: uploadedAt,
      );

      final map = report.toFirestore();

      expect(map.containsKey('cloudinaryPublicId'), isFalse);
      expect(map.containsKey('aiSummary'), isFalse);
      expect(map.containsKey('analysisJson'), isFalse);
    });

    test('includes optional fields when present', () {
      final report = ReportModel(
        id: 'r2',
        userId: 'u1',
        name: 'Test',
        category: 'Blood Test',
        storageUrl: 'https://example.com/r.pdf',
        uploadedAt: uploadedAt,
        cloudinaryPublicId: 'cid_abc',
        aiSummary: 'Normal results.',
        analysisJson: {'results': []},
      );

      final map = report.toFirestore();

      expect(map['cloudinaryPublicId'], 'cid_abc');
      expect(map['aiSummary'], 'Normal results.');
      expect(map['analysisJson'], {'results': []});
    });

    test('writes uploadedAt as Timestamp', () {
      final report = ReportModel(
        id: 'r3',
        userId: 'u1',
        name: 'Test',
        category: 'Other',
        storageUrl: '',
        uploadedAt: uploadedAt,
      );

      final map = report.toFirestore();
      expect(map['uploadedAt'], isA<Timestamp>());
    });
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  group('ReportModel.copyWith', () {
    final original = ReportModel(
      id: 'r1',
      userId: 'u1',
      name: 'CBC',
      category: 'Blood Test',
      storageUrl: 'https://example.com/r.pdf',
      uploadedAt: uploadedAt,
    );

    test('updates aiSummary and analysisJson', () {
      final updated = original.copyWith(
        aiSummary: 'All normal',
        analysisJson: {'key': 'value'},
      );
      expect(updated.aiSummary, 'All normal');
      expect(updated.analysisJson, {'key': 'value'});
    });

    test('preserves immutable fields after copy', () {
      final updated = original.copyWith(aiSummary: 'Updated');
      expect(updated.id, 'r1');
      expect(updated.userId, 'u1');
      expect(updated.name, 'CBC');
      expect(updated.uploadedAt, uploadedAt);
    });
  });
}
