import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../providers/report_provider.dart' as global;
import '../models/report_models.dart';

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() => const ReportState();

  Future<void> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final ext = (file.extension ?? 'pdf').toLowerCase();
    final mime = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';

    state = state.copyWith(
      fileName: file.name,
      fileBytes: file.bytes,
      mimeType: mime,
      phase: ReportScreenPhase.upload,
    );
  }

  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    state = state.copyWith(
      fileName: picked.name,
      fileBytes: bytes,
      mimeType: 'image/jpeg',
      phase: ReportScreenPhase.upload,
    );
  }

  Future<void> analyzeReport() async {
    if (!state.hasFile) return;

    state = state.copyWith(
      phase: ReportScreenPhase.processing,
      processingStep: 0,
    );

    // Write bytes to a temp file — AiVisionService requires a File handle.
    final File tmpFile = File(
      '${Directory.systemTemp.path}'
      '/curo_report_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    try {
      await tmpFile.writeAsBytes(state.fileBytes!, flush: true);

      state = state.copyWith(processingStep: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(processingStep: 2);

      // Groq vision: grayscale + contrast boost → parseLabReport.
      final raw = await AiVisionService.instance.parseLabReport(tmpFile);
      final result = ReportAnalysisResult.fromGroqJson(raw);

      // Save to Cloudinary + Firestore in background.
      _persistReport(result);

      state = state.copyWith(
        phase: ReportScreenPhase.results,
        results: result.results,
        summary: result.summary,
        meta: result.meta,
        processingStep: 3,
        expandedSet: const {},
      );
    } catch (e) {
      state = state.copyWith(
        phase: ReportScreenPhase.error,
        error: _friendlyError(e),
      );
    } finally {
      try {
        await tmpFile.delete();
      } catch (_) {}
    }
  }

  void _persistReport(ReportAnalysisResult result) {
    final bytes = state.fileBytes;
    final filename = state.fileName ?? 'report';
    if (bytes == null) return;

    // ── Build a structural title from the AI payload ──────────────────────────
    // Prefer the lab name returned by Groq; fall back to "Lab Report".
    final labPrefix =
        (result.meta.labName.isNotEmpty && result.meta.labName != 'Lab')
        ? result.meta.labName
        : 'Lab Report';

    // Append up to 3 parameter names so the title is self-describing.
    final paramPart = result.results.map((r) => r.testName).take(3).join(', ');
    final name = paramPart.isNotEmpty
        ? '$labPrefix — $paramPart'
        : '$labPrefix — ${result.summary.headline}';

    // ── Infer category from parameter names ───────────────────────────────────
    final allParams = result.results
        .map((r) => r.testName.toLowerCase())
        .join(' ');
    final String category;
    if (allParams.contains('urine') ||
        allParams.contains('urinalysis') ||
        allParams.contains('urea creatinine')) {
      category = 'Urine';
    } else if (allParams.contains('ecg') ||
        allParams.contains('ekg') ||
        allParams.contains('cardiac')) {
      category = 'ECG';
    } else if (allParams.contains('x-ray') ||
        allParams.contains('xray') ||
        allParams.contains('mri')) {
      category = 'X-Ray';
    } else {
      category = 'Blood Test';
    }

    // ── Use patient_friendly_summary as the stored aiSummary ─────────────────
    final aiSummary = result.summary.body.isNotEmpty
        ? result.summary.body
        : result.summary.headline;

    final analysisJson = <String, dynamic>{
      'patientName': result.meta.patientName,
      'labName': result.meta.labName,
      'date': result.meta.date,
      'summaryHeadline': result.summary.headline,
      'summary': result.summary.body,
      'criticalAlerts': result.summary.criticalAlerts,
      'results': result.results
          .map(
            (r) => {
              'testName': r.testName,
              'value': r.value,
              'unit': r.unit,
              'refRangeLow': r.refRangeLow,
              'refRangeHigh': r.refRangeHigh,
              'status': r.status.name,
              'aiExplanation': r.aiExplanation,
              'learnMoreTopic': r.learnMoreTopic,
            },
          )
          .toList(),
    };

    ref
        .read(global.reportUploadProvider.notifier)
        .uploadBytes(
          bytes: bytes,
          filename: filename,
          name: name,
          category: category,
          aiSummary: aiSummary,
          analysisJson: analysisJson,
        );
  }

  String _friendlyError(Object e) {
    if (e is AiVisionException) {
      final msg = e.message;
      if (msg.contains('GROQ_API_KEY')) {
        return 'AI service is not configured. Contact support.';
      }
      if (msg.contains('timed out')) {
        return 'Analysis timed out. Please try again with a smaller file.';
      }
      if (msg.contains('Network error')) {
        return 'No network connection. Please check your connection and try again.';
      }
      return msg;
    }
    final msg = e.toString();
    if (msg.contains('timeout') || msg.contains('TimeoutException')) {
      return 'Analysis timed out. Please try again with a smaller file.';
    }
    final clean = msg.replaceFirst('Exception: ', '');
    return clean.isNotEmpty ? clean : 'Analysis failed. Please try again.';
  }

  void toggleExpanded(int index) {
    final current = Set<int>.from(state.expandedSet);
    if (current.contains(index)) {
      current.remove(index);
    } else {
      current.add(index);
    }
    state = state.copyWith(expandedSet: current);
  }

  void reset() => state = const ReportState();
}

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(
  ReportNotifier.new,
);
