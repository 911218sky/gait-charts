import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 統一的安全儲存配置，集中管理各平台的 FlutterSecureStorage 選項。
///
/// - Android：AES256-GCM + RSA 加密
/// - iOS/macOS：系統 Keychain
/// - Web：localStorage（僅 Base64 編碼）
/// - Windows/Linux：Credential Manager / libsecret
class SecureStorageConfig {
  SecureStorageConfig._();

  /// 全域 FlutterSecureStorage 實例，所有 storage 類別應使用此實例。
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    // Android：AES256-GCM + RSA 加密
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    
    // iOS：系統 Keychain
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    
    // Web：localStorage（僅 Base64 編碼，無真實加密）
    webOptions: WebOptions(
      dbName: 'gait_charts_secure_storage',
      publicKey: 'gait_charts_v1',
    ),
    
    // macOS：系統 Keychain
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    
    // Linux：libsecret
    lOptions: LinuxOptions(),
    
    // Windows：Credential Manager
    wOptions: WindowsOptions(),
  );
}