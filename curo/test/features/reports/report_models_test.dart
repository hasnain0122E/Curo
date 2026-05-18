import 'dart:typed_data';

import 'package:curo/features/reports/models/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── LabResult.displayValue / _fmt ──────────────────────────────────────────

  group('LabResult formatting', () {
    LabResult lr(double value, {double low = 4.0, double high = 10.0}) =>
        LabResult(
          testName: 'WBC',
          value: value,
          unit: 'K/μL',
          refRangeLow: low,
          refRangeHigh: high,
          status: LabStatus.normal,
        );

    test('displayValue shows integer for whole numbers', () {
      expect(lr(7.0).displayValue, '7');
    });

    test('displayValue shows 1 decimal for non-whole numbers', () {
      expect(lr(7.5).displayValue, '7.5');
    });

    test('displayValue shows 1 decimal for x.5 values', () {
      expect(lr(7.5).displayValue, '7.5');
      expect(lr(4.2).displayValue, '4.2');
    });

    test('refRangeLabel formats correctly with integer bounds', () {
      final result = lr(7.0, low: 4.0, high: 10.0);
      expect(result.refRangeLabel, 'Ref. Range: 4 - 10 K/μL');
    });

    test('refRangeLabel uses decimals for non-whole bounds', () {
      final result = lr(7.0, low: 3.5, high: 10.5);
      expect(result.refRangeLabel, 'Ref. Range: 3.5 - 10.5 K/μL');
    });
  });

  // ── ReportAnalysisResult.tryParseGeminiJson ───────────────────────────────

  group('ReportAnalysisResult.tryParseGeminiJson', () {
    test('parses plain JSON string', () {
      const raw = '{"patientName": "Ali", "results": []}';
      final result = ReportAnalysisResult.tryParseGeminiJson(raw);

      expect(result, isNotNull);
      expect(result!['patientName'], 'Ali');
    });

    test('strips ```json code fences', () {
      const raw = '```json\n{"patientName": "Sara"}\n```';
      final result = ReportAnalysisResult.tryParseGeminiJson(raw);

      expect(result, isNotNull);
      expect(result!['patientName'], 'Sara');
    });

    test('strips plain ``` code fences', () {
      const raw = '```\n{"labName": "Chughtai"}\n```';
      final result = ReportAnalysisResult.tryParseGeminiJson(raw);

      expect(result, isNotNull);
      expect(result!['labName'], 'Chughtai');
    });

    test('extracts JSON embedded in surrounding prose', () {
      const raw = 'Here is the analysis: {"results": []} More text.';
      final result = ReportAnalysisResult.tryParseGeminiJson(raw);

      expect(result, isNotNull);
      expect(result!['results'], isEmpty);
    });

    test('returns null for unparseable input', () {
      expect(ReportAnalysisResult.tryParseGeminiJson('not json'), isNull);
      expect(ReportAnalysisResult.tryParseGeminiJson(''), isNull);
      expect(ReportAnalysisResult.tryParseGeminiJson('{bad json}'), isNull);
    });
  });

  // ── ReportAnalysisResult.fromJson ─────────────────────────────────────────

  group('ReportAnalysisResult.fromJson', () {
    Map<String, dynamic> validJson({String status = 'normal'}) => {
          'patientName': 'Ahmed',
          'labName': 'Chughtai Lab',
          'date': '2024-05-10',
          'summaryHeadline': 'All Normal',
          'summary': 'All parameters within normal range.',
          'results': [
            {
              'testName': 'Haemoglobin',
              'value': 14.5,
              'unit': 'g/dL',
              'refRangeLow': 13.0,
              'refRangeHigh': 17.0,
              'status': status,
              'aiExplanation': 'Normal',
            }
          ],
        };

    test('parses meta fields correctly', () {
      final r = ReportAnalysisResult.fromJson(validJson());

      expect(r.meta.patientName, 'Ahmed');
      expect(r.meta.labName, 'Chughtai Lab');
      expect(r.meta.date, '2024-05-10');
    });

    test('parses summary correctly', () {
      final r = ReportAnalysisResult.fromJson(validJson());

      expect(r.summary.headline, 'All Normal');
      expect(r.summary.testsAnalyzed, 1);
    });

    test('parses lab result with normal status', () {
      final r = ReportAnalysisResult.fromJson(validJson(status: 'normal'));

      expect(r.results.first.status, LabStatus.normal);
    });

    test('parses lab result with high status', () {
      final r = ReportAnalysisResult.fromJson(validJson(status: 'high'));

      expect(r.results.first.status, LabStatus.high);
    });

    test('parses lab result with low status', () {
      final r = ReportAnalysisResult.fromJson(validJson(status: 'low'));

      expect(r.results.first.status, LabStatus.low);
    });

    test('unknown status string falls back to normal', () {
      final r = ReportAnalysisResult.fromJson(validJson(status: 'unknown'));

      expect(r.results.first.status, LabStatus.normal);
    });

    test('criticalAlerts counts non-normal results', () {
      final json = {
        'patientName': 'P', 'labName': 'L', 'date': 'd',
        'summaryHeadline': 'H', 'summary': 'S',
        'results': [
          {'testName': 'A', 'value': 14.5, 'unit': 'g/dL',
           'refRangeLow': 13.0, 'refRangeHigh': 17.0, 'status': 'high'},
          {'testName': 'B', 'value': 5.0, 'unit': 'K/μL',
           'refRangeLow': 4.0, 'refRangeHigh': 10.0, 'status': 'normal'},
          {'testName': 'C', 'value': 2.0, 'unit': 'g/dL',
           'refRangeLow': 4.0, 'refRangeHigh': 6.0, 'status': 'low'},
        ],
      };

      final r = ReportAnalysisResult.fromJson(json);
      expect(r.summary.criticalAlerts, 2);
    });

    test('handles empty results list', () {
      final json = {
        'patientName': 'P', 'labName': 'L', 'date': 'd',
        'summaryHeadline': 'H', 'summary': 'S', 'results': [],
      };
      final r = ReportAnalysisResult.fromJson(json);
      expect(r.results, isEmpty);
      expect(r.summary.testsAnalyzed, 0);
      expect(r.summary.criticalAlerts, 0);
    });

    test('uses defaults for missing top-level fields', () {
      final r = ReportAnalysisResult.fromJson({});

      expect(r.meta.patientName, 'Patient');
      expect(r.meta.labName, 'Lab');
      expect(r.summary.headline, 'Analysis Complete');
    });
  });

  // ── ReportState ───────────────────────────────────────────────────────────

  group('ReportState', () {
    test('hasFile is false initially', () {
      const state = ReportState();
      expect(state.hasFile, isFalse);
    });

    test('hasFile is true when fileBytes is set', () {
      final state = ReportState(fileBytes: Uint8List.fromList([1, 2, 3]));
      expect(state.hasFile, isTrue);
    });

    test('copyWith updates phase and processingStep', () {
      const original = ReportState();
      final updated = original.copyWith(
        phase: ReportScreenPhase.processing,
        processingStep: 2,
      );
      expect(updated.phase, ReportScreenPhase.processing);
      expect(updated.processingStep, 2);
    });

    test('copyWith preserves expandedSet', () {
      const original = ReportState(expandedSet: {0, 2});
      final updated = original.copyWith(processingStep: 1);
      expect(updated.expandedSet, {0, 2});
    });
  });
}
