import 'dart:convert';
import 'dart:typed_data';

enum LabStatus { normal, high, low }

enum ReportScreenPhase { upload, processing, results, error }

class LabResult {
  const LabResult({
    required this.testName,
    required this.value,
    required this.unit,
    required this.refRangeLow,
    required this.refRangeHigh,
    required this.status,
    this.aiExplanation,
    this.learnMoreTopic,
  });

  final String testName;
  final double value;
  final String unit;
  final double refRangeLow;
  final double refRangeHigh;
  final LabStatus status;
  final String? aiExplanation;
  final String? learnMoreTopic;

  String get refRangeLabel =>
      'Ref. Range: ${_fmt(refRangeLow)} - ${_fmt(refRangeHigh)} $unit';

  String get displayValue => _fmt(value);

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class AiSummary {
  const AiSummary({
    required this.headline,
    required this.body,
    required this.testsAnalyzed,
    required this.criticalAlerts,
  });

  final String headline;
  final String body;
  final int testsAnalyzed;
  final int criticalAlerts;
}

class ReportMeta {
  const ReportMeta({
    required this.patientName,
    required this.labName,
    required this.date,
  });

  final String patientName;
  final String labName;
  final String date;
}

class ReportState {
  const ReportState({
    this.phase = ReportScreenPhase.upload,
    this.fileName,
    this.fileBytes,
    this.mimeType,
    this.processingStep = 0,
    this.results = const [],
    this.summary,
    this.meta,
    this.error,
    this.expandedSet = const {},
  });

  final ReportScreenPhase phase;
  final String? fileName;
  final Uint8List? fileBytes;
  final String? mimeType;
  final int processingStep;
  final List<LabResult> results;
  final AiSummary? summary;
  final ReportMeta? meta;
  final String? error;
  final Set<int> expandedSet;

  bool get hasFile => fileBytes != null;

  ReportState copyWith({
    ReportScreenPhase? phase,
    String? fileName,
    Uint8List? fileBytes,
    String? mimeType,
    int? processingStep,
    List<LabResult>? results,
    AiSummary? summary,
    ReportMeta? meta,
    String? error,
    Set<int>? expandedSet,
  }) =>
      ReportState(
        phase: phase ?? this.phase,
        fileName: fileName ?? this.fileName,
        fileBytes: fileBytes ?? this.fileBytes,
        mimeType: mimeType ?? this.mimeType,
        processingStep: processingStep ?? this.processingStep,
        results: results ?? this.results,
        summary: summary ?? this.summary,
        meta: meta ?? this.meta,
        error: error ?? this.error,
        expandedSet: expandedSet ?? this.expandedSet,
      );
}

// ── JSON parsing ──────────────────────────────────────────────────────────────

class ReportAnalysisResult {
  const ReportAnalysisResult({
    required this.meta,
    required this.summary,
    required this.results,
  });

  final ReportMeta meta;
  final AiSummary summary;
  final List<LabResult> results;

  factory ReportAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    final results = rawResults.map((r) {
      final low = (r['refRangeLow'] as num?)?.toDouble() ?? 0;
      final high = (r['refRangeHigh'] as num?)?.toDouble() ?? 0;
      final value = (r['value'] as num?)?.toDouble() ?? 0;
      final statusStr = (r['status'] as String? ?? 'normal').toLowerCase();
      final status = statusStr == 'high'
          ? LabStatus.high
          : statusStr == 'low'
              ? LabStatus.low
              : LabStatus.normal;
      return LabResult(
        testName: r['testName'] as String? ?? '',
        value: value,
        unit: r['unit'] as String? ?? '',
        refRangeLow: low,
        refRangeHigh: high,
        status: status,
        aiExplanation: r['aiExplanation'] as String?,
        learnMoreTopic: r['learnMoreTopic'] as String?,
      );
    }).toList();

    final criticalAlerts =
        results.where((r) => r.status != LabStatus.normal).length;

    return ReportAnalysisResult(
      meta: ReportMeta(
        patientName: json['patientName'] as String? ?? 'Patient',
        labName: json['labName'] as String? ?? 'Lab',
        date: json['date'] as String? ?? '',
      ),
      summary: AiSummary(
        headline: json['summaryHeadline'] as String? ?? 'Analysis Complete',
        body: json['summary'] as String? ?? '',
        testsAnalyzed: results.length,
        criticalAlerts: json['criticalAlerts'] as int? ?? criticalAlerts,
      ),
      results: results,
    );
  }

  static ReportAnalysisResult get mock => const ReportAnalysisResult(
        meta: ReportMeta(
          patientName: 'Ali Ahmed',
          labName: 'Chughtai Lab',
          date: 'Oct 12, 2023',
        ),
        summary: AiSummary(
          headline: 'Review Required',
          body: 'Most markers are within range, but your Blood Sugar levels '
              'require clinical attention.',
          testsAnalyzed: 3,
          criticalAlerts: 1,
        ),
        results: [
          LabResult(
            testName: 'Hemoglobin',
            value: 14.2,
            unit: 'g/dL',
            refRangeLow: 13.5,
            refRangeHigh: 17.5,
            status: LabStatus.normal,
          ),
          LabResult(
            testName: 'Blood Sugar (Fasting)',
            value: 126,
            unit: 'mg/dL',
            refRangeLow: 70,
            refRangeHigh: 100,
            status: LabStatus.high,
            aiExplanation:
                'Your fasting sugar is elevated, which may indicate '
                'pre-diabetes. Consult your doctor for a HbA1c screening.',
            learnMoreTopic: 'Diabetes',
          ),
          LabResult(
            testName: 'White Blood Cell Count',
            value: 7.8,
            unit: 'x10⁹/L',
            refRangeLow: 4.5,
            refRangeHigh: 11.0,
            status: LabStatus.normal,
          ),
        ],
      );

  // Strips markdown code fences and locates the first JSON object.
  static Map<String, dynamic>? tryParseGeminiJson(String raw) {
    try {
      var text = raw;
      final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
      final m = fence.firstMatch(text);
      if (m != null) text = m.group(1)!.trim();

      final s = text.indexOf('{');
      final e = text.lastIndexOf('}');
      if (s != -1 && e > s) text = text.substring(s, e + 1);

      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
