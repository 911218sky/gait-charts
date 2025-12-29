import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 統一的安全儲存配置。
///
/// 集中管理所有平台的 FlutterSecureStorage 選項，確保：
/// - Android：使用自定義 AES256-GCM + RSA 加密（flutter_secure_storage v10+ 內建）
/// - iOS/macOS：使用系統 Keychain（預設行為）
/// - Web：使用 localStorage（僅 Base64 編碼，無真實加密）
/// - Windows/Linux：使用系統 Credential Manager / libsecret
class SecureStorageConfig {
  SecureStorageConfig._();

  /// 全域統一的 FlutterSecureStorage 實例。
  ///
  /// 使用 const 建構子確保單例，所有 storage 類別應使用此實例。
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    // Android 選項：使用自定義 AES256-GCM + RSA 加密實作
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    
    // iOS 選項：使用系統 Keychain（預設已足夠安全）
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    
    // Web 選項：使用專屬的 localStorage 命名空間
    // 注意：Web 平台僅使用 Base64 編碼，無真實系統加密
    webOptions: WebOptions(
      dbName: 'gait_charts_secure_storage',
      publicKey: 'gait_charts_v1',
    ),
    
    // macOS 選項：使用系統 Keychain
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    
    // Linux 選項：使用預設值（libsecret）
    lOptions: LinuxOptions(),
    
    // Windows 選項：使用預設值（Credential Manager）
    wOptions: WindowsOptions(),
  );
}