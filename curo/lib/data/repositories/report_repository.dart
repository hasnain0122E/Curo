import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../services/cloudinary_service.dart';

class ReportRepository {
  ReportRepository({
    required FirebaseFirestore firestore,
    required CloudinaryService cloudinary,
  }) : _firestore = firestore,
       _cloudinary = cloudinary;

  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  /// Subcollection path: users/{uid}/reports
  CollectionReference<ReportModel> _reportsOf(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('reports')
      .withConverter<ReportModel>(
        fromFirestore: (snap, _) => ReportModel.fromFirestore(snap),
        toFirestore: (model, _) => model.toFirestore(),
      );

  /// Uploads file bytes to Cloudinary then saves metadata to Firestore.
  Future<ReportModel> uploadReportBytes({
    required String userId,
    required Uint8List bytes,
    required String filename,
    required String name,
    required String category,
    String? aiSummary,
    Map<String, dynamic>? analysisJson,
  }) async {
    final result = await _cloudinary.uploadBytes(
      bytes,
      folder: 'curo_reports/$userId',
      filename: filename,
    );
    return _saveMetadata(
      userId: userId,
      secureUrl: result.secureUrl,
      publicId: result.publicId,
      name: name,
      category: category,
      aiSummary: aiSummary,
      analysisJson: analysisJson,
    );
  }

  /// Uploads a local File to Cloudinary then saves metadata to Firestore.
  Future<ReportModel> uploadReport({
    required String userId,
    required File file,
    required String name,
    required String category,
    String? aiSummary,
    Map<String, dynamic>? analysisJson,
  }) async {
    final result = await _cloudinary.upload(
      file,
      folder: 'curo_reports/$userId',
    );
    return _saveMetadata(
      userId: userId,
      secureUrl: result.secureUrl,
      publicId: result.publicId,
      name: name,
      category: category,
      aiSummary: aiSummary,
      analysisJson: analysisJson,
    );
  }

  Future<ReportModel> _saveMetadata({
    required String userId,
    required String secureUrl,
    required String publicId,
    required String name,
    required String category,
    String? aiSummary,
    Map<String, dynamic>? analysisJson,
  }) async {
    final docRef = _reportsOf(userId).doc();
    final report = ReportModel(
      id: docRef.id,
      userId: userId,
      name: name,
      category: category,
      storageUrl: secureUrl,
      cloudinaryPublicId: publicId,
      aiSummary: aiSummary,
      analysisJson: analysisJson,
      uploadedAt: DateTime.now(),
    );
    await docRef.set(report);
    return report;
  }

  Stream<List<ReportModel>> watchUserReports(String userId) {
    return _reportsOf(userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> updateAiSummary(
    String userId,
    String reportId,
    String summary, {
    Map<String, dynamic>? analysisJson,
  }) async {
    final update = <String, dynamic>{'aiSummary': summary};
    if (analysisJson != null) update['analysisJson'] = analysisJson;
    await _reportsOf(userId).doc(reportId).update(update);
  }

  /// Parses the Cloudinary public_id from a secure URL.
  /// Input:  https://res.cloudinary.com/[cloud]/image/upload/v1234/curo_reports/uid/file.jpg
  /// Output: curo_reports/uid/file
  static String? _extractCloudinaryPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1 || uploadIdx + 1 >= segments.length) return null;
      var start = uploadIdx + 1;
      // Skip optional version segment (v12345)
      if (start < segments.length &&
          RegExp(r'^v\d+$').hasMatch(segments[start])) {
        start++;
      }
      if (start >= segments.length) return null;
      final last = segments.last;
      final dot = last.lastIndexOf('.');
      final lastNoExt = dot != -1 ? last.substring(0, dot) : last;
      final pathSegments = [
        ...segments.sublist(start, segments.length - 1),
        lastNoExt,
      ];
      return pathSegments.join('/');
    } catch (_) {
      return null;
    }
  }

  /// Dual-stage deletion: Cloudinary first (best-effort), then Firestore.
  Future<void> deleteReport(
    String userId,
    String reportId, {
    String? storageUrl,
    String? cloudinaryPublicId,
  }) async {
    final publicId =
        (cloudinaryPublicId != null && cloudinaryPublicId.isNotEmpty)
        ? cloudinaryPublicId
        : (storageUrl != null ? _extractCloudinaryPublicId(storageUrl) : null);
    if (publicId != null) {
      try {
        await _cloudinary.delete(publicId);
      } catch (_) {}
    }
    await _reportsOf(userId).doc(reportId).delete();
  }
}
