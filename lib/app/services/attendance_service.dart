import 'package:academia/app/data/models/attendance_model.dart';
import 'package:academia/app/data/repositories/attendance_repository.dart';

class AttendanceService {
  AttendanceService({required AttendanceRepository repository})
    : _repository = repository;

  final AttendanceRepository _repository;

  Future<List<AttendanceModel>> fetchAttendanceByBatch(String batchId) {
    return _repository.fetchAttendanceByBatch(batchId);
  }
}
