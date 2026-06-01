import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.storageUrl,
    required this.uploadedAt,
    this.cloudinaryPublicId,
    this.aiSummary,
    this.analysisJson,
  });

  final String id;
  final String userId;
  final String name;
  final String category; // 'Blood Test' | 'X-Ray' | 'MRI' | 'ECG' | 'Other'
  final String storageUrl;
  final String? cloudinaryPublicId;
  final String? aiSummary;
  final Map<String, dynamic>? analysisJson;
  final DateTime uploadedAt;

  factory ReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final rawAnalysis = data['analysisJson'];
    final Map<String, dynamic>? analysis = rawAnalysis is String
        ? jsonDecode(rawAnalysis) as Map<String, dynamic>?
        : rawAnalysis as Map<String, dynamic>?;
    return ReportModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      storageUrl: data['storageUrl'] as String? ?? '',
      cloudinaryPublicId: data['cloudinaryPublicId'] as String?,
      aiSummary: data['aiSummary'] as String?,
      analysisJson: analysis,
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'category': category,
    'storageUrl': storageUrl,
    if (cloudinaryPublicId != null) 'cloudinaryPublicId': cloudinaryPublicId,
    if (aiSummary != null) 'aiSummary': aiSummary,
    if (analysisJson != null) 'analysisJson': analysisJson,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
  };

  ReportModel copyWith({
    String? aiSummary,
    Map<String, dynamic>? analysisJson,
  }) => ReportModel(
    id: id,
    userId: userId,
    name: name,
    category: category,
    storageUrl: storageUrl,
    cloudinaryPublicId: cloudinaryPublicId,
    aiSummary: aiSummary ?? this.aiSummary,
    analysisJson: analysisJson ?? this.analysisJson,
    uploadedAt: uploadedAt,
  );
}
