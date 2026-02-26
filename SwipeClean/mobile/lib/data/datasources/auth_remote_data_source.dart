import '../../core/network/api_client.dart';
import '../../domain/entities/auth_tokens.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<void> register(String email, String password) async {
    await _apiClient.dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
    });
  }

  Future<AuthTokens> login(String email, String password) async {
    final response = await _apiClient.dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });

    return AuthTokens(
      accessToken: response.data['accessToken'] as String,
      refreshToken: response.data['refreshToken'] as String,
    );
  }
}
