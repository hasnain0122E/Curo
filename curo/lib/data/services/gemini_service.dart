import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/reports/models/report_models.dart';

// Pass at build time: flutter run --dart-define-from-file=dart_defines/secrets.json
const kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

class GeminiService {
  GeminiService._();

  static const _model = 'gemini-1.5-flash';
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

  // ── 1. Analyze medical lab report ─────────────────────────────────────────

  static const _analyzePrompt = '''
You are a medical lab report analyst. Analyze the provided lab report and extract all test results.
Return ONLY a valid JSON object (no markdown, no explanation):
{
  "patientName": "string or Patient if not found",
  "labName": "string or Lab if not found",
  "date": "string or empty",
  "summaryHeadline": "2-4 word headline like All Clear or Review Required",
  "summary": "2-3 sentence plain-language summary of the overall health picture",
  "criticalAlerts": number,
  "results": [
    {
      "testName": "exact test name",
      "value": number,
      "unit": "unit string",
      "refRangeLow": number,
      "refRangeHigh": number,
      "status": "normal | high | low",
      "aiExplanation": "1-2 sentence plain-language explanation for abnormal only, null otherwise",
      "learnMoreTopic": "short keyword for abnormal only, null otherwise"
    }
  ]
}''';

  static Future<ReportAnalysisResult> analyzeReport({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    _assertApiKey();
    return await _withRetry(() async {
      final res = await _genModel().generateContent([
        Content.multi([DataPart(mimeType, bytes), TextPart(_analyzePrompt)]),
      ]);
      final text = res.text;
      if (text == null || text.isEmpty) throw Exception('Empty response from Gemini.');
      final json = ReportAnalysisResult.tryParseGeminiJson(text);
      if (json == null) throw Exception('Could not parse Gemini response.');
      return ReportAnalysisResult.fromJson(json);
    });
  }

  // ── 2. Scan prescription — returns medicine names for Firebase lookup ──────

  static const _prescriptionPrompt = '''
You are a pharmacy assistant. Extract all medicine names from this prescription image (handwritten or printed).
Return ONLY a valid JSON array (no markdown, no explanation):
[{"name": "medicine brand or generic name", "dosage": "e.g. 500mg or empty string", "frequency": "e.g. 2x daily or empty string", "duration": "e.g. 7 days or empty string"}]
If no medicines are visible return an empty array [].''';

  static Future<List<String>> scanPrescription(Uint8List bytes) async {
    _assertApiKey();
    return await _withRetry(() async {
      final res = await _genModel(temperature: 0.0).generateContent([
        Content.multi([
          DataPart('image/jpeg', bytes),
          TextPart(_prescriptionPrompt),
        ]),
      ]);
      return _parsePrescriptionNames(res.text ?? '');
    });
  }

  static List<String> _parsePrescriptionNames(String raw) {
    try {
      var text = raw;
      final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
      final m = fence.firstMatch(text);
      if (m != null) text = m.group(1)!.trim();
      final s = text.indexOf('[');
      final e = text.lastIndexOf(']');
      if (s == -1 || e <= s) return [];
      final list = jsonDecode(text.substring(s, e + 1)) as List;
      return list
          .map((item) => (item as Map<String, dynamic>)['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── 3. Chat with report ───────────────────────────────────────────────────

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
      final res = await _genModel(temperature: 0.7).generateContent([
        Content.text(prompt),
      ]);
      final answer = res.text ?? '';
      return answer + (language == 'ur' ? _urduDisclaimer : _disclaimer);
    });
  }
}
