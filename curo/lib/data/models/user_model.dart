import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.phone,
    required this.createdAt,
    this.name,
    this.email,
  });

  final String uid;
  final String phone;
  final String? name;
  final String? email;
  final DateTime createdAt;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      phone: data['phone'] as String? ?? '',
      name: data['name'] as String?,
      email: data['email'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'phone': phone,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({String? name, String? email}) => UserModel(
        uid: uid,
        phone: phone,
        name: name ?? this.name,
        email: email ?? this.email,
        createdAt: createdAt,
      );
}
