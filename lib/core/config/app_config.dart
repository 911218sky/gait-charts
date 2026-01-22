import 'package:flutter/foundation.dart';

/// 後端連線設定，包含 API 基礎網址、逾時與簽章驗證參數。
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

  /// API 基礎網址
  final String baseUrl;

  /// 請求逾時時間
  final Duration requestTimeout;

  /// 是否啟用後端 HMAC 簽章驗證（對應後端 AUTH_ENABLED）。
  /// 若啟用，須提供 [authClientId] 與 [authClientSecret]，否則 API 呼叫會被拒絕。
  final bool authEnabled;

  /// 請求簽章使用的 client_id（對應後端 X-Client-Id）。
  final String authClientId;

  /// 請求簽章使用的密鑰（對應後端 client secret）。
  /// 前端存放 secret 並非嚴格安全，僅為配合現有後端驗證機制。
  final String authClientSecret;

  /// 簽章版本（對應後端 X-Signature-Version；預設 v1）。
  final String authSignatureVersion;

  /// 免簽章路徑前綴清單，用於 upload/multipart 等尚未支援簽章的端點。
  final List<String> authExemptPathPrefixes;

  /// 是否啟用 request body gzip 壓縮。後端須支援 `Content-Encoding: gzip` 解壓。
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

/// 本地開發預設設定。
const defaultAppConfig = AppConfig(
  baseUrl: 'https://nycu-realsense-pose.sky1218.com/api/v1',
  // baseUrl: 'http://localhost:8100/api/v1',
  requestTimeout: Duration(seconds: 20),
);
