import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/auth_usecases.dart';
import 'presentation/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authDataSource = AuthRemoteDataSource(apiClient);
  final authRepository = AuthRepositoryImpl(authDataSource, tokenStorage);
  final authUseCases = AuthUseCases(authRepository);

  runApp(SwipeCleanApp(authUseCases: authUseCases));
}

class SwipeCleanApp extends StatelessWidget {
  final AuthUseCases authUseCases;

  const SwipeCleanApp({super.key, required this.authUseCases});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeClean',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: LoginScreen(authUseCases: authUseCases),
    );
  }
}
