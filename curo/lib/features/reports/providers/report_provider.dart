import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/report_provider.dart' as global;
import '../models/report_models.dart';
import '../services/gemini_report_service.dart';

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

    // Step 1 — uploading to Cloudinary
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(processingStep: 1);

    // Step 2 — reading values with Gemini
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(processingStep: 2);

    // Step 3 — actual AI analysis
    try {
      final result = await GeminiReportService.analyze(
        fileBytes: state.fileBytes!,
        mimeType: state.mimeType ?? 'image/jpeg',
      );

      // Step 4 — save to Cloudinary + Firestore in background
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
    }
  }

  void _persistReport(ReportAnalysisResult result) {
    final bytes = state.fileBytes;
    final filename = state.fileName ?? 'report';
    if (bytes == null) return;

    // Derive a human-readable category from the Gemini result
    final name = result.meta.patientName != 'Patient'
        ? '${result.meta.labName} – ${result.meta.date}'
        : filename;
    const category = 'Blood Test'; // default; UI can improve this

    final analysisJson = <String, dynamic>{
      'patientName': result.meta.patientName,
      'labName': result.meta.labName,
      'date': result.meta.date,
      'summaryHeadline': result.summary.headline,
      'summary': result.summary.body,
      'criticalAlerts': result.summary.criticalAlerts,
      'results': result.results.map((r) => {
        'testName': r.testName,
        'value': r.value,
        'unit': r.unit,
        'refRangeLow': r.refRangeLow,
        'refRangeHigh': r.refRangeHigh,
        'status': r.status.name,
        'aiExplanation': r.aiExplanation,
        'learnMoreTopic': r.learnMoreTopic,
      }).toList(),
    };

    ref.read(global.reportUploadProvider.notifier).uploadBytes(
      bytes: bytes,
      filename: filename,
      name: name,
      category: category,
      aiSummary: result.summary.headline,
      analysisJson: analysisJson,
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('API key')) {
      return 'AI service is not configured. Contact support.';
    }
    if (msg.contains('timeout') || msg.contains('TimeoutException')) {
      return 'Analysis timed out. Please try again with a smaller file.';
    }
    if (msg.contains('empty response') || msg.contains('Empty response')) {
      return 'The AI could not read the document. Try a clearer, well-lit photo.';
    }
    if (msg.contains('Could not read') || msg.contains('Could not parse')) {
      return 'The AI response was unexpected. Please try again.';
    }
    // Surface the real error message so issues are diagnosable.
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
