import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

    // Step 1 — uploading
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(processingStep: 1);

    // Step 2 — reading values
    await Future.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(processingStep: 2);

    // Step 3 — AI analysis (actual API call)
    try {
      final result = await GeminiReportService.analyze(
        fileBytes: state.fileBytes!,
        mimeType: state.mimeType ?? 'image/jpeg',
      );
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
        error: 'Analysis failed. Please try again.',
      );
    }
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
