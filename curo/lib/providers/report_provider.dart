import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/report_model.dart';
import 'app_providers.dart';

/// Live stream of the signed-in user's reports from their subcollection.
final userReportsProvider =
    StreamProvider.autoDispose<List<ReportModel>>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  final user = authAsync.asData?.value;
  if (user == null) return Stream.value([]);
  return ref.watch(reportRepositoryProvider).watchUserReports(user.uid);
});

// ── Upload state ──────────────────────────────────────────────────────────────

class ReportUploadState {
  const ReportUploadState({
    this.isUploading = false,
    this.error,
    this.lastUploaded,
  });
  final bool isUploading;
  final String? error;
  final ReportModel? lastUploaded;
}

class ReportUploadNotifier extends Notifier<ReportUploadState> {
  @override
  ReportUploadState build() => const ReportUploadState();

  /// Upload raw bytes (from file_picker or camera) + Gemini analysis result.
  Future<ReportModel?> uploadBytes({
    required Uint8List bytes,
    required String filename,
    required String name,
    required String category,
    String? aiSummary,
    Map<String, dynamic>? analysisJson,
  }) async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) {
      state = const ReportUploadState(error: 'Not signed in.');
      return null;
    }
    state = const ReportUploadState(isUploading: true);
    try {
      final report =
          await ref.read(reportRepositoryProvider).uploadReportBytes(
                userId: user.uid,
                bytes: bytes,
                filename: filename,
                name: name,
                category: category,
                aiSummary: aiSummary,
                analysisJson: analysisJson,
              );
      state = ReportUploadState(lastUploaded: report);
      return report;
    } catch (e) {
      state = ReportUploadState(error: e.toString());
      return null;
    }
  }

  /// Upload a local File + optional Gemini analysis result.
  Future<ReportModel?> upload({
    required File file,
    required String name,
    required String category,
    String? aiSummary,
    Map<String, dynamic>? analysisJson,
  }) async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    if (user == null) {
      state = const ReportUploadState(error: 'Not signed in.');
      return null;
    }
    state = const ReportUploadState(isUploading: true);
    try {
      final report = await ref.read(reportRepositoryProvider).uploadReport(
            userId: user.uid,
            file: file,
            name: name,
            category: category,
            aiSummary: aiSummary,
            analysisJson: analysisJson,
          );
      state = ReportUploadState(lastUploaded: report);
      return report;
    } catch (e) {
      state = ReportUploadState(error: e.toString());
      return null;
    }
  }
}

final reportUploadProvider =
    NotifierProvider<ReportUploadNotifier, ReportUploadState>(
        ReportUploadNotifier.new);
