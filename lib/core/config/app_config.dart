import 'package:flutter/foundation.dart';

/// 封裝後端連線設定與共用逾時參數。
@immutable
class AppConfig {
  const AppConfig({
    required this.baseUrl,
    this.requestTimeout = const Duration(seconds: 20),
    this.authEnabled = const bool.fromEnvironment('AUTH_ENABLED', defaultValue: true),
    this.authClientId = const String.fromEnvironment('AUTH_CLIENT_ID', defaultValue: 'nycu-realsense-pose'),
    this.authClientSecret = const String.fromEnvironment('AUTH_CLIENT_SECRET', defaultValue: '4Az9dmwCD4ejhjqPj7Zv'),
    this.authSignatureVersion =
        const String.fromEnvironment('AUTH_SIGNATURE_VERSION', defaultValue: 'v1'),
    this.authExemptPathPrefixes = const <String>[],
    this.requestCompressionEnabled =
        const bool.fromEnvironment('REQUEST_COMPRESSION_ENABLED', defaultValue: true),
  });

  final String baseUrl; // API 基礎網址
  final Duration requestTimeout; // 請求逾時時間

  /// 是否啟用後端 HMAC 簽章驗證（對應後端 AUTH_ENABLED）。
  ///
  /// 注意：若啟用，務必提供 [authClientId] / [authClientSecret]，否則所有 API 呼叫會被後端拒絕。
  final bool authEnabled;

  /// 請求簽章使用的 client_id（對應後端 X-Client-Id）。
  final String authClientId;

  /// 請求簽章使用的密鑰（對應後端 client secret）。
  ///
  /// 注意：把 secret 放在前端不是嚴格安全；這裡是為了與目前後端驗證機制對接。
  final String authClientSecret;

  /// 簽章版本（對應後端 X-Signature-Version；預設 v1）。
  final String authSignatureVersion;

  /// 客戶端側免簽章路徑（以 prefix 判斷）。
  ///
  /// 用途：例如 upload/multipart 等客戶端尚未支援簽章的路徑。
  final List<String> authExemptPathPrefixes;

  /// 是否啟用 request body 壓縮（gzip）。
  ///
  /// 注意：後端必須支援 `Content-Encoding: gzip` 的解壓，否則會無法解析 body。
  final bool requestCompressionEnabled;

  /// 產生帶有覆蓋值的新設定。
  AppConfig copyWith({
    String? baseUrl,
    Duration? requestTimeout,
    bool? authEnabled,
    String? authClientId,
    String? authClientSecret,
    String? authSignatureVersion,
    List<String>? authExemptPathPrefixes,
    bool? requestCompressionEnabled,
  }) {
    return AppConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      authEnabled: authEnabled ?? this.authEnabled,
      authClientId: authClientId ?? this.authClientId,
      authClientSecret: authClientSecret ?? this.authClientSecret,
      authSignatureVersion: authSignatureVersion ?? this.authSignatureVersion,
      authExemptPathPrefixes: authExemptPathPrefixes ?? this.authExemptPathPrefixes,
      requestCompressionEnabled: requestCompressionEnabled ?? this.requestCompressionEnabled,
    );
  }
}

/// 本地開發預設設定，可由 provider 注入。
const defaultAppConfig = AppConfig(
  baseUrl: 'https://nycu-realsense-pose.sky1218.com/v1/',
  // baseUrl: 'http://localhost:8100/v1',
  requestTimeout: Duration(seconds: 20),
);
