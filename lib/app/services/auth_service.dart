import 'package:academia/app/data/models/user_model.dart';
import 'package:academia/app/data/repositories/auth_repository.dart';

class AuthService {
  AuthService({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  Future<UserModel?> login({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }

  Future<UserModel?> getCurrentUserProfile() {
    return _repository.getCurrentUserProfile();
  }

  Future<void> logout() {
    return _repository.logout();
  }
}
