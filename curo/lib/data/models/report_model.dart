import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.storageUrl,
    required this.uploadedAt,
    this.aiSummary,
  });

  final String id;
  final String userId;
  final String name;
  final String category; // 'Blood Test' | 'X-Ray' | 'MRI' | 'ECG' | 'Other'
  final String storageUrl;
  final String? aiSummary;
  final DateTime uploadedAt;

  factory ReportModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReportModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      storageUrl: data['storageUrl'] as String? ?? '',
      aiSummary: data['aiSummary'] as String?,
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'category': category,
        'storageUrl': storageUrl,
        if (aiSummary != null) 'aiSummary': aiSummary,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
      };

  ReportModel copyWith({String? aiSummary}) => ReportModel(
        id: id,
        userId: userId,
        name: name,
        category: category,
        storageUrl: storageUrl,
        aiSummary: aiSummary ?? this.aiSummary,
        uploadedAt: uploadedAt,
      );
}
