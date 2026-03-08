import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.expertise,
    this.education,
    this.experience,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? expertise;
  final String? education;
  final String? experience;
  final DateTime? createdAt;

  factory UserModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final Object? createdAtRaw = map['createdAt'];

    return UserModel(
      id: id,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: (map['role'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'approved',
      expertise: map['expertise'] as String?,
      education: map['education'] as String?,
      experience: map['experience'] as String?,
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : createdAtRaw is DateTime
          ? createdAtRaw
          : null,
    );
  }
}
