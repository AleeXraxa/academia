import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/repositories/batch_repository.dart';

class BatchService {
  BatchService({required BatchRepository repository}) : _repository = repository;

  final BatchRepository _repository;

  Future<List<BatchModel>> fetchBatches() {
    return _repository.fetchBatches();
  }
}
