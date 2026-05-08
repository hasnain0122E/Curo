import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../services/cloudinary_service.dart';

class ReportRepository {
  ReportRepository({
    required FirebaseFirestore firestore,
    required CloudinaryService cloudinary,
  })  : _firestore = firestore,
        _cloudinary = cloudinary;

  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  CollectionReference<ReportModel> get _reports => _firestore
      .collection('reports')
      .withConverter<ReportModel>(
        fromFirestore: (snap, _) => ReportModel.fromFirestore(snap),
        toFirestore: (model, _) => model.toFirestore(),
      );

  /// Uploads file to Cloudinary and saves metadata to Firestore.
  Future<ReportModel> uploadReport({
    required String userId,
    required File file,
    required String name,
    required String category,
    String? aiSummary,
  }) async {
    final url = await _cloudinary.upload(
      file,
      folder: 'curo_reports/$userId',
    );

    final docRef = _reports.doc();
    final report = ReportModel(
      id: docRef.id,
      userId: userId,
      name: name,
      category: category,
      storageUrl: url,
      aiSummary: aiSummary,
      uploadedAt: DateTime.now(),
    );
    await docRef.set(report);
    return report;
  }

  Stream<List<ReportModel>> watchUserReports(String userId) {
    return _reports
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> updateAiSummary(String reportId, String summary) async {
    await _reports.doc(reportId).update({'aiSummary': summary});
  }

  Future<void> deleteReport(String reportId, String storageUrl) async {
    await _reports.doc(reportId).delete();
    await _cloudinary.delete(storageUrl);
  }
}
