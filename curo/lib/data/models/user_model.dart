import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
  });

  final String uid;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final DateTime createdAt;

  String get name {
    final parts = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : '';
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
  }) =>
      UserModel(
        uid: uid,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        createdAt: createdAt,
      );
}
