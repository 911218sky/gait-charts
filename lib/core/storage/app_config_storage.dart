import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gait_charts/core/storage/secure_storage_config.dart';

/// AppConfig 本機持久化，目前只存 baseUrl。
/// 使用 SecureStorageConfig 確保跨平台加密一致性。
class AppConfigStorage {
  AppConfigStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageConfig.instance;

  final FlutterSecureStorage _storage;

  static const String _kBaseUrlKey = 'app_config.base_url';

  Future<String?> readBaseUrl() async {
    final value = await _storage.read(key: _kBaseUrlKey);
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> writeBaseUrl(String baseUrl) async {
    await _storage.write(key: _kBaseUrlKey, value: baseUrl);
  }

  Future<void> clearBaseUrl() async {
    await _storage.delete(key: _kBaseUrlKey);
  }
}
