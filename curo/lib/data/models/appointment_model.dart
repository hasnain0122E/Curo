import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.labId,
    required this.labName,
    required this.doctorName,
    required this.specialty,
    required this.appointmentDate,
    required this.timeSlot,
    required this.feeRs,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String userId;
  final String labId;
  final String labName;
  final String doctorName;
  final String specialty;
  final DateTime appointmentDate;
  final String timeSlot;
  final int feeRs;
  final String status; // 'upcoming' | 'completed' | 'cancelled'
  final DateTime createdAt;
  final String? notes;

  bool get isUpcoming => status == 'upcoming';

  factory AppointmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppointmentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      labId: data['labId'] as String? ?? '',
      labName: data['labName'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      appointmentDate:
          (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      feeRs: data['feeRs'] as int? ?? 0,
      status: data['status'] as String? ?? 'upcoming',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'labId': labId,
    'labName': labName,
    'doctorName': doctorName,
    'specialty': specialty,
    'appointmentDate': Timestamp.fromDate(appointmentDate),
    'timeSlot': timeSlot,
    'feeRs': feeRs,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    if (notes != null) 'notes': notes,
  };

  AppointmentModel copyWith({String? status, String? notes}) =>
      AppointmentModel(
        id: id,
        userId: userId,
        labId: labId,
        labName: labName,
        doctorName: doctorName,
        specialty: specialty,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        feeRs: feeRs,
        status: status ?? this.status,
        createdAt: createdAt,
        notes: notes ?? this.notes,
      );
}
