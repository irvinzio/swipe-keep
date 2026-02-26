import 'package:dio/dio.dart';
import '../config/app_env.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({required this.tokenStorage}) : dio = Dio(BaseOptions(baseUrl: AppEnv.apiBaseUrl)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && error.requestOptions.path != '/api/auth/refresh') {
          final refresh = await tokenStorage.readRefreshToken();
          if (refresh != null) {
            try {
              final refreshResponse = await dio.post('/api/auth/refresh', data: {'refreshToken': refresh});
              final newAccess = refreshResponse.data['accessToken'] as String;
              final newRefresh = refreshResponse.data['refreshToken'] as String;
              await tokenStorage.saveTokens(newAccess, newRefresh);

              final request = error.requestOptions;
              request.headers['Authorization'] = 'Bearer $newAccess';
              final retry = await dio.fetch(request);
              return handler.resolve(retry);
            } catch (_) {
              await tokenStorage.clear();
            }
          }
        }
        handler.next(error);
      },
    ));
  }
}
