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
  }) => ReportState(
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

    final criticalAlerts = results
        .where((r) => r.status != LabStatus.normal)
        .length;

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

  /// Parses the Groq `parseLabReport` response envelope.
  ///
  /// Expected shape:
  /// ```json
  /// {
  ///   "report_analysis": {
  ///     "overall_status": "Normal|Requires Attention|Critical Alert",
  ///     "metrics": [
  ///       { "parameter": "...", "patient_value": "...",
  ///         "reference_range": "...", "unit": "...",
  ///         "flag": "Normal|High|Low", "patient_explanation": "..." }
  ///     ]
  ///   }
  /// }
  /// ```
  factory ReportAnalysisResult.fromGroqJson(Map<String, dynamic> json) {
    final analysis = (json['report_analysis'] as Map<String, dynamic>?) ?? {};
    final rawMetrics = (analysis['metrics'] as List<dynamic>?) ?? [];

    final results = rawMetrics.whereType<Map<String, dynamic>>().map((m) {
      final flagStr = (m['flag'] as String? ?? 'Normal').toLowerCase();
      final status = flagStr == 'high'
          ? LabStatus.high
          : flagStr == 'low'
          ? LabStatus.low
          : LabStatus.normal;

      final value = double.tryParse(m['patient_value'] as String? ?? '') ?? 0.0;
      final (low, high) = _parseRefRange(m['reference_range'] as String? ?? '');

      return LabResult(
        testName: m['parameter'] as String? ?? '',
        value: value,
        unit: m['unit'] as String? ?? '',
        refRangeLow: low,
        refRangeHigh: high,
        status: status,
        aiExplanation: m['patient_explanation'] as String?,
      );
    }).toList();

    final overallStatus =
        analysis['overall_status'] as String? ?? 'Analysis Complete';
    final criticalAlerts = results
        .where((r) => r.status != LabStatus.normal)
        .length;

    return ReportAnalysisResult(
      meta: ReportMeta(
        patientName: analysis['patient_name'] as String? ?? 'Patient',
        labName: analysis['lab_name'] as String? ?? 'Lab',
        date: analysis['report_date'] as String? ?? '',
      ),
      summary: AiSummary(
        headline: overallStatus,
        body:
            analysis['patient_friendly_summary'] as String? ??
            analysis['summary'] as String? ??
            '',
        testsAnalyzed: results.length,
        criticalAlerts: criticalAlerts,
      ),
      results: results,
    );
  }

  /// Parses strings like "4.0 - 11.0", "4–11", "<5.0", ">1.0"
  /// into a (low, high) double pair for [LabResult.refRangeLow/High].
  static (double, double) _parseRefRange(String raw) {
    final dashMatch = RegExp(r'([\d.]+)\s*[-–]\s*([\d.]+)').firstMatch(raw);
    if (dashMatch != null) {
      return (
        double.tryParse(dashMatch.group(1)!) ?? 0.0,
        double.tryParse(dashMatch.group(2)!) ?? 0.0,
      );
    }
    final ltMatch = RegExp(r'<\s*([\d.]+)').firstMatch(raw);
    if (ltMatch != null) {
      return (0.0, double.tryParse(ltMatch.group(1)!) ?? 0.0);
    }
    final gtMatch = RegExp(r'>\s*([\d.]+)').firstMatch(raw);
    if (gtMatch != null) {
      return (double.tryParse(gtMatch.group(1)!) ?? 0.0, 999.0);
    }
    return (0.0, 0.0);
  }

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
