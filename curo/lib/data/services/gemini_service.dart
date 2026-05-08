import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/reports/models/report_models.dart';

// ── API Key ───────────────────────────────────────────────────────────────────
// Pass at build time: flutter run --dart-define-from-file=dart_defines/secrets.json
// See dart_defines/secrets.json.example for the required format.
const kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

// ── GeminiService ─────────────────────────────────────────────────────────────

class GeminiService {
  GeminiService._();

  static const _model = 'gemini-1.5-flash';
  static const _timeout = Duration(seconds: 45);

  static GenerativeModel _model_({double temperature = 0.1}) => GenerativeModel(
    model: _model,
    apiKey: kGeminiApiKey,
    generationConfig: GenerationConfig(
      temperature: temperature,
      responseMimeType: 'text/plain',
    ),
  );

  // Retries once on timeout; all other errors bubble to caller.
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
    return await _withRetry(() async {
      final res = await _model_().generateContent([
        Content.multi([DataPart(mimeType, bytes), TextPart(_analyzePrompt)]),
      ]);
      final text = res.text;
      if (text == null || text.isEmpty) throw Exception('Empty response from AI.');
      final json = ReportAnalysisResult.tryParseGeminiJson(text);
      if (json == null) throw Exception('Could not parse AI response.');
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
    if (kGeminiApiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      return ['Amoxicillin', 'Metformin', 'Omeprazole', 'Panadol'];
    }
    try {
      return await _withRetry(() async {
        final res = await _model_(temperature: 0.0).generateContent([
          Content.multi([
            DataPart('image/jpeg', bytes),
            TextPart(_prescriptionPrompt),
          ]),
        ]);
        return _parsePrescriptionNames(res.text ?? '');
      });
    } catch (_) {
      return [];
    }
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
          .map(
            (item) => (item as Map<String, dynamic>)['name'] as String? ?? '',
          )
          .where((n) => n.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── 3. Chat with report ───────────────────────────────────────────────────

  static Future<String> chatWithReport({
    required String question,
    required Map<String, dynamic> reportData,
    String language = 'en',
  }) async {
    if (kGeminiApiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return language == 'ur'
          ? 'آپ کی رپورٹ میں زیادہ تر قدریں نارمل حد میں ہیں۔ براہ کرم اپنے ڈاکٹر سے مشورہ کریں۔'
          : 'Based on your report, most values appear within normal range. Please consult your doctor for a complete interpretation.';
    }

    final tone = language == 'ur'
        ? 'Respond in Urdu. Use simple, warm, conversational language.'
        : 'Respond in plain English. Be warm, clear, and easy to understand.';

    final prompt =
        '''
You are a helpful medical assistant. $tone
Answer the patient's question based on their lab report data below.
Always remind them to consult their doctor for any medical decisions.

Report Data:
${jsonEncode(reportData)}

Patient Question: $question''';

    try {
      return await _withRetry(() async {
        final res = await _model_(
          temperature: 0.7,
        ).generateContent([Content.text(prompt)]);
        return res.text ?? _fallback(language);
      });
    } catch (_) {
      return _fallback(language);
    }
  }

  static String _fallback(String lang) => lang == 'ur'
      ? 'معاف کریں، ابھی جواب نہیں دے سکتا۔ دوبارہ کوشش کریں۔'
      : 'Unable to process your question right now. Please try again.';
}
