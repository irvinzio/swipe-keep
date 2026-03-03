import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/photo_action_app.dart';

class PhotoAppPreferenceStorage {
  static const _preferredPhotoAppKey = 'preferred_photo_action_app';
  static const _promptShownKey = 'preferred_photo_action_app_prompt_shown';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<PhotoActionApp?> readPreferredApp() async {
    final value = await _storage.read(key: _preferredPhotoAppKey);
    if (value == null || value.isEmpty) return null;
    return PhotoActionAppX.fromValue(value);
  }

  Future<void> savePreferredApp(PhotoActionApp app) {
    return _storage.write(key: _preferredPhotoAppKey, value: app.value);
  }

  Future<bool> hasShownPrompt() async {
    final shown = await _storage.read(key: _promptShownKey);
    return shown == 'true';
  }

  Future<void> markPromptAsShown() {
    return _storage.write(key: _promptShownKey, value: 'true');
  }
}
