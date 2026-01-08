import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/network/signing/request_signer.dart';

/// 自動補上後端要求的 HMAC 簽章 headers。
///
/// Headers: X-Client-Id, X-Nonce, X-Timestamp, X-Signature, X-Signature-Version
class SignedHeadersInterceptor extends Interceptor {
  SignedHeadersInterceptor({
    required this.config,
    RequestSigner? signer,
  }) : _signer = signer ?? RequestSigner();

  final AppConfig config;
  final RequestSigner _signer;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!config.authEnabled) {
      handler.next(options);
      return;
    }

    // 放行 preflight
    if (options.method.toUpperCase() == 'OPTIONS') {
      handler.next(options);
      return;
    }

    final uri = options.uri;
    final path = Uri.decodeFull(uri.path);
    // 如果 path 在 exemptPathPrefixes 中，則不進行簽章
    if (_isExemptPath(path)) {
      handler.next(options);
      return;
    }

    final clientId = config.authClientId.trim();
    final secret = config.authClientSecret;
    if (clientId.isEmpty || secret.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: '已啟用 AUTH，但未設定 AUTH_CLIENT_ID / AUTH_CLIENT_SECRET',
        ),
      );
      return;
    }

    final nonce = _signer.generateNonceHex();
    // 後端要求 Unix timestamp（秒）
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    final String bodySha256;
    try {
      bodySha256 = _signer.bodySha256Hex(options.data);
    } on UnsupportedError catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: '此 request body 不支援簽章（${e.message}）。'
              '若後端要求必簽，請改用 JSON body 或把此 path 加到 client 端 authExemptPathPrefixes。',
        ),
      );
      return;
    }

    final msg = _signer.canonicalString(
      method: options.method,
      path: path,
      query: uri.query,
      nonce: nonce,
      timestamp: timestamp,
      bodySha256: bodySha256,
      version: config.authSignatureVersion.trim().isEmpty
          ? 'v1'
          : config.authSignatureVersion.trim(),
    );

    final signature = _signer.signatureHex(
      secret: Uint8List.fromList(utf8.encode(secret)),
      message: msg,
    );

    options.headers['X-Client-Id'] = clientId;
    options.headers['X-Nonce'] = nonce;
    options.headers['X-Timestamp'] = timestamp;
    options.headers['X-Signature'] = signature;
    options.headers['X-Signature-Version'] = config.authSignatureVersion.trim();

    handler.next(options);
  }

  /// 檢查 path 是否在免簽章清單中
  bool _isExemptPath(String path) {
    if (config.authExemptPathPrefixes.isEmpty) {
      return false;
    }
    for (final p in config.authExemptPathPrefixes) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;
      if (path.startsWith(trimmed)) return true;
    }
    return false;
  }
}


