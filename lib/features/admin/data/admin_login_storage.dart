import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gait_charts/core/storage/secure_storage_config.dart';

/// 儲存登入表單的「記住帳號/密碼」設定。
///
/// - 統一使用 flutter_secure_storage 跨平台儲存敏感資料。
/// - Android：使用 EncryptedSharedPreferences + AES256-GCM 加密。
/// - iOS/macOS：使用系統 Keychain（first_unlock 可訪問性）。
/// - Windows/Linux：使用系統 Credential Manager / libsecret（加密能力依系統而定）。
/// - Web：使用 localStorage（僅 Base64 編碼，無真實加密），請在 UI 提示風險。
///
/// 使用統一的 SecureStorageConfig 確保所有平台配置一致。
class AdminLoginStorage {
  AdminLoginStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageConfig.instance;

  final FlutterSecureStorage _storage;

  static const _kRememberKey = 'admin.login.remember';
  static const _kUsernameKey = 'admin.login.username';
  static const _kPasswordKey = 'admin.login.password';

  Future<RememberedLogin?> read() async {
    final remember = await _storage.read(key: _kRememberKey);
    final username = await _storage.read(key: _kUsernameKey);
    final password = await _storage.read(key: _kPasswordKey);

    if (remember != 'true') {
      return null;
    }
    if (username == null || username.trim().isEmpty) {
      return null;
    }
    return RememberedLogin(
      username: username.trim(),
      password: password,
    );
  }

  Future<void> save({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _kRememberKey, value: 'true');
    await _storage.write(key: _kUsernameKey, value: username.trim());
    await _storage.write(key: _kPasswordKey, value: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kRememberKey);
    await _storage.delete(key: _kUsernameKey);
    await _storage.delete(key: _kPasswordKey);
  }
}

class RememberedLogin {
  RememberedLogin({required this.username, this.password});

  final String username;
  final String? password;
}

