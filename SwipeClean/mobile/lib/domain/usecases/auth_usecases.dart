import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class AuthUseCases {
  final AuthRepository _repository;

  AuthUseCases(this._repository);

  Future<void> register(String email, String password) => _repository.register(email, password);
  Future<AuthTokens> login(String email, String password) => _repository.login(email, password);
  Future<void> logout() => _repository.logout();
}
