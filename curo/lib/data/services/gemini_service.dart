import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/reports/models/report_models.dart';

// Injected at build time via: flutter run --dart-define-from-file=dart_defines/secrets.json
// Falls back to the embedded key for development builds.
const kGeminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'AIzaSyCUO4pwP0v6qvRvWGcRgm7XnReGXpoMaME',
);

class GeminiService {
  GeminiService._();

  static const _model = 'gemini-2.0-flash';
  static const _timeout = Duration(seconds: 45);

  static GenerativeModel _genModel({double temperature = 0.1}) =>
      GenerativeModel(
        model: _model,
        apiKey: kGeminiApiKey,
        generationConfig: GenerationConfig(
          temperature: temperature,
          responseMimeType: 'text/plain',
        ),
      );

  static void _assertApiKey() {
    if (kGeminiApiKey.isEmpty) {
      throw Exception(
        'Gemini API key is not configured. '
        'Run with: flutter run --dart-define-from-file=dart_defines/secrets.json',
      );
    }
  }

  static Future<T> _withRetry<T>(Future<T> Function() fn) async {
    try {
      return await fn().timeout(_timeout);
    } on TimeoutException {
      return await fn().timeout(_timeout);
    }
  }

  // ── 1. Analyze medical document (lab report OR prescription) ─────────────────
  // HARDCODED: Returns demo data. Replace with real Gemini call when ready.

  static Future<ReportAnalysisResult> analyzeReport({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return _mockReportResult();
  }

  static ReportAnalysisResult _mockReportResult() {
    final results = [
      const LabResult(
        testName: 'Hemoglobin',
        value: 10.5,
        unit: 'g/dL',
        refRangeLow: 13.0,
        refRangeHigh: 17.0,
        status: LabStatus.low,
        aiExplanation:
            'Your hemoglobin is below the normal range, indicating mild anemia. '
            'Common symptoms include fatigue and shortness of breath. '
            'Iron supplementation may be recommended by your doctor.',
        learnMoreTopic: 'anemia',
      ),
      const LabResult(
        testName: 'WBC Count',
        value: 7.2,
        unit: 'x10³/μL',
        refRangeLow: 4.0,
        refRangeHigh: 11.0,
        status: LabStatus.normal,
      ),
      const LabResult(
        testName: 'Platelet Count',
        value: 210,
        unit: 'x10³/μL',
        refRangeLow: 150,
        refRangeHigh: 400,
        status: LabStatus.normal,
      ),
      const LabResult(
        testName: 'Blood Sugar (Fasting)',
        value: 92,
        unit: 'mg/dL',
        refRangeLow: 70,
        refRangeHigh: 100,
        status: LabStatus.normal,
      ),
      const LabResult(
        testName: 'Creatinine',
        value: 1.8,
        unit: 'mg/dL',
        refRangeLow: 0.6,
        refRangeHigh: 1.2,
        status: LabStatus.high,
        aiExplanation:
            'Elevated creatinine may indicate reduced kidney function. '
            'Stay well hydrated and follow up with your doctor for further evaluation.',
        learnMoreTopic: 'kidney function',
      ),
      const LabResult(
        testName: 'ALT (SGPT)',
        value: 28,
        unit: 'U/L',
        refRangeLow: 7,
        refRangeHigh: 56,
        status: LabStatus.normal,
      ),
    ];

    final user = FirebaseAuth.instance.currentUser;
    final patientName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Patient';

    return ReportAnalysisResult(
      meta: ReportMeta(
        patientName: patientName,
        labName: 'Chughtai Lab',
        date: '10 May 2025',
      ),
      summary: AiSummary(
        headline: 'Review Required',
        body:
            'Your report shows mild anemia with low hemoglobin and slightly '
            'elevated creatinine levels. Other parameters including white blood '
            'cells and platelets are within normal range. Please consult your physician.',
        testsAnalyzed: results.length,
        criticalAlerts: 2,
      ),
      results: results,
    );
  }

  // ── 2. Scan prescription — returns medicine names for Firebase lookup ──────
  // HARDCODED: Returns demo data. Replace with real Gemini call when ready.

  static Future<List<String>> scanPrescription(Uint8List bytes) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      'Augmentin 625mg',
      'Panadol 500mg',
      'Omeprazole 20mg',
      'Brufen 400mg',
    ];
  }

  // ── 3. Scan lab test prescription — returns test names for lab lookup ────────
  // HARDCODED: Returns demo data. Replace with real Gemini call when ready.

  static Future<List<String>> scanLabTestPrescription(Uint8List bytes) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return ['CBC', 'LFT', 'Blood Sugar Fasting', 'Urine DR'];
  }

  // ── 4. Chat with report ───────────────────────────────────────────────────

  static const _disclaimer =
      '\n\n⚠️ This is an AI-generated response for informational purposes only. '
      'Always consult a qualified healthcare professional for medical decisions.';

  static const _urduDisclaimer =
      '\n\n⚠️ یہ صرف معلوماتی مقاصد کے لیے AI کا جواب ہے۔ '
      'طبی فیصلوں کے لیے ہمیشہ کسی اہل ڈاکٹر سے مشورہ کریں۔';

  static Future<String> chatWithReport({
    required String question,
    required Map<String, dynamic> reportData,
    String language = 'en',
  }) async {
    _assertApiKey();

    final tone = language == 'ur'
        ? 'Respond in Urdu. Use simple, warm, conversational language.'
        : 'Respond in plain English. Be warm, clear, and easy to understand.';

    final prompt =
        'You are a helpful medical assistant. $tone\n'
        'Answer the patient\'s question based on their lab report data below.\n'
        'Report Data:\n${jsonEncode(reportData)}\n\n'
        'Patient Question: $question';

    return await _withRetry(() async {
      final res = await _genModel(
        temperature: 0.7,
      ).generateContent([Content.text(prompt)]);
      final answer = res.text ?? '';
      return answer + (language == 'ur' ? _urduDisclaimer : _disclaimer);
    });
  }
}
