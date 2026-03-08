import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/data/repositories/student_repository.dart';

class StudentService {
  StudentService({required StudentRepository repository}) : _repository = repository;

  final StudentRepository _repository;

  Future<List<StudentModel>> fetchStudents() {
    return _repository.fetchStudents();
  }
}
