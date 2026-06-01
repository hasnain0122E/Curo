import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    required this.labId,
    required this.labName,
    required this.testName,
    required this.date,
    required this.timeSlot,
    required this.priceRs,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String labId;
  final String labName;
  final String testName;
  final DateTime date;
  final String timeSlot;
  final int priceRs;
  final String status; // 'upcoming' | 'completed' | 'cancelled'
  final DateTime createdAt;

  bool get isUpcoming => status == 'upcoming';

  factory BookingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      labId: data['labId'] as String? ?? '',
      labName: data['labName'] as String? ?? '',
      testName: data['testName'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      priceRs: data['priceRs'] as int? ?? 0,
      status: data['status'] as String? ?? 'upcoming',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'labId': labId,
    'labName': labName,
    'testName': testName,
    'date': Timestamp.fromDate(date),
    'timeSlot': timeSlot,
    'priceRs': priceRs,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
