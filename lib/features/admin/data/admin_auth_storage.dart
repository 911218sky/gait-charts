import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gait_charts/core/storage/secure_storage_config.dart';

/// 儲存管理員登入 token 與過期時間。
///
/// 使用統一的 SecureStorageConfig 確保跨平台加密一致性。
/// 敏感資料（token）應優先使用此類別儲存。
class AdminAuthStorage {
  AdminAuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageConfig.instance;

  final FlutterSecureStorage _storage;

  static const String _kTokenKey = 'admin.auth.token';
  static const String _kExpiresKey = 'admin.auth.expires_at';

  // 儲存 token 與過期時間
  Future<void> saveToken({
    required String token,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _kTokenKey, value: token);
    await _storage.write(key: _kExpiresKey, value: expiresAt.toIso8601String());
  }

  // 讀取 token 與過期時間
  Future<StoredToken?> readToken() async {
    final token = (await _storage.read(key: _kTokenKey))?.trim();
    final expiresRaw = (await _storage.read(key: _kExpiresKey))?.trim();
    if (token == null || token.isEmpty || expiresRaw == null) {
      return null;
    }
    final expiresAt = DateTime.tryParse(expiresRaw);
    if (expiresAt == null) {
      return null;
    }
    return StoredToken(token: token, expiresAt: expiresAt);
  }

  // 清除 token 與過期時間
  Future<void> clear() async {
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kExpiresKey);
  }
}

// 儲存 token 與過期時間
class StoredToken {
  StoredToken({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;
}