class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.batchId,
    required this.studentId,
    required this.status,
    required this.date,
  });

  final String id;
  final String batchId;
  final String studentId;
  final String status;
  final DateTime date;
}
