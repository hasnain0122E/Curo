import 'dart:typed_data';
import '../../../data/services/gemini_service.dart';
import '../models/report_models.dart';

class GeminiReportService {
  GeminiReportService._();

  static Future<ReportAnalysisResult> analyze({
    required Uint8List fileBytes,
    required String mimeType,
  }) => GeminiService.analyzeReport(bytes: fileBytes, mimeType: mimeType);
}
