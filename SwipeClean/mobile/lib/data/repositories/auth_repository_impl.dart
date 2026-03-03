import '../../core/storage/token_storage.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<void> register(String email, String password) => _remote.register(email, password);

  @override
  Future<AuthTokens> login(String email, String password) async {
    final tokens = await _remote.login(email, password);
    await _storage.saveTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }

  @override
  Future<void> logout() => _storage.clear();
}
