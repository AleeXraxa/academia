import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  const StudentModel({
    required this.id,
    required this.name,
    this.studentId,
    required this.email,
    required this.contactNo,
    required this.parentContact,
    required this.gender,
    required this.status,
    this.batchId,
    this.batchName,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? studentId;
  final String email;
  final String contactNo;
  final String parentContact;
  final String gender;
  final String status;
  final String? batchId;
  final String? batchName;
  final DateTime? createdAt;

  factory StudentModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final Object? createdAtRaw = map['createdAt'];
    return StudentModel(
      id: id,
      name: (map['name'] as String?) ?? '',
      studentId: map['studentId'] as String?,
      email: (map['email'] as String?) ?? '',
      contactNo: (map['contactNo'] as String?) ?? '',
      parentContact: (map['parentContact'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'active',
      batchId: map['batchId'] as String?,
      batchName: map['batchName'] as String?,
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : createdAtRaw is DateTime
          ? createdAtRaw
          : null,
    );
  }
}
