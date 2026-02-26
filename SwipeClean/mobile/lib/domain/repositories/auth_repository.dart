import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<void> register(String email, String password);
  Future<AuthTokens> login(String email, String password);
  Future<void> logout();
}
