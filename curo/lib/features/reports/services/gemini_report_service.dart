import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/report_models.dart';

const _kApiKey = 'YOUR_GEMINI_API_KEY';

const _kPrompt = '''
You are a medical lab report analyst. Analyze the provided lab report image and extract all test results.

Return ONLY a valid JSON object with this exact structure (no markdown, no explanation):
{
  "patientName": "string or Patient if not found",
  "labName": "string or Lab if not found",
  "date": "string or empty",
  "summaryHeadline": "2-4 word headline like 'All Clear' or 'Review Required'",
  "summary": "2-3 sentence plain-language summary of the overall health picture",
  "criticalAlerts": number,
  "results": [
    {
      "testName": "exact test name from report",
      "value": number,
      "unit": "unit string",
      "refRangeLow": number,
      "refRangeHigh": number,
      "status": "normal | high | low",
      "aiExplanation": "1-2 sentence plain-language explanation (only for abnormal results, null otherwise)",
      "learnMoreTopic": "short topic keyword for abnormal results, null otherwise"
    }
  ]
}
''';

class GeminiReportService {
  GeminiReportService._();

  static Future<ReportAnalysisResult> analyze({
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    if (_kApiKey == 'YOUR_GEMINI_API_KEY') {
      await Future.delayed(const Duration(seconds: 3));
      return ReportAnalysisResult.mock;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _kApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'text/plain',
        ),
      );

      final imagePart = DataPart(mimeType, fileBytes);
      final textPart = TextPart(_kPrompt);

      final response = await model.generateContent([
        Content.multi([imagePart, textPart]),
      ]);

      final raw = response.text ?? '';
      final json = ReportAnalysisResult.tryParseGeminiJson(raw);
      if (json == null) return ReportAnalysisResult.mock;
      return ReportAnalysisResult.fromJson(json);
    } catch (_) {
      return ReportAnalysisResult.mock;
    }
  }
}
