import 'package:cloud_firestore/cloud_firestore.dart';

class BatchModel {
  const BatchModel({
    required this.id,
    required this.name,
    required this.schedule,
    this.semester,
    this.curriculam,
    this.days,
    this.timing,
    this.startDate,
    this.teacherId,
    this.teacherName,
    this.status,
    this.studentsCount,
    this.createdAt,
  });

  final String id;
  final String name;
  final String schedule;
  final String? semester;
  final String? curriculam;
  final List<String>? days;
  final String? timing;
  final DateTime? startDate;
  final String? teacherId;
  final String? teacherName;
  final String? status;
  final int? studentsCount;
  final DateTime? createdAt;

  factory BatchModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final Object? createdAtRaw = map['createdAt'];
    final Object? startDateRaw = map['startDate'];
    final Object? studentsRaw = map['studentsCount'] ?? map['studentCount'];
    final List<String> normalizedDays = ((map['days'] as List?) ?? <dynamic>[])
        .map((dynamic day) => '$day'.trim())
        .where((String day) => day.isNotEmpty)
        .toList();

    return BatchModel(
      id: id,
      name: (map['name'] as String?) ??
          (map['batchName'] as String?) ??
          'Untitled Batch',
      schedule: (map['schedule'] as String?) ??
          (map['timing'] as String?) ??
          '--',
      semester: map['semester'] as String?,
      curriculam: map['curriculam'] as String?,
      days: normalizedDays,
      timing: map['timing'] as String?,
      startDate: startDateRaw is Timestamp
          ? startDateRaw.toDate()
          : startDateRaw is DateTime
          ? startDateRaw
          : null,
      teacherId: (map['teacherId'] as String?) ??
          (map['teacherUid'] as String?) ??
          (map['assignedTeacherId'] as String?),
      teacherName: (map['teacherName'] as String?) ??
          (map['teacher'] as String?),
      status: map['status'] as String?,
      studentsCount: studentsRaw is int ? studentsRaw : int.tryParse('$studentsRaw'),
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : createdAtRaw is DateTime
          ? createdAtRaw
          : null,
    );
  }
}
