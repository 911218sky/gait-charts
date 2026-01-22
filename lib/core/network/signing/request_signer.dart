import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// 後端請求簽章工具（HMAC-SHA256）。
///
/// Canonical string 格式：version, METHOD, path[?query], nonce, timestamp, body_sha256
class RequestSigner {
  RequestSigner({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// 產生 nonce（hex 字串），預設 16 bytes => 32 hex chars。
  String generateNonceHex({int bytes = 16}) {
    if (bytes <= 0) {
      throw ArgumentError.value(bytes, 'bytes', 'must be > 0');
    }
    final data = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      data[i] = _random.nextInt(256);
    }
    return _toHex(data);
  }

  /// 將 request body 正規化為 bytes。
  ///
  /// 支援 null、String、`List<int>`、Uint8List、Map、List。
  /// 其他型別（FormData/Stream）會拋錯，避免產生無效簽章。
  Uint8List normalizeBodyBytes(Object? body) {
    if (body == null) {
      return Uint8List(0);
    }
    if (body is Uint8List) {
      return body;
    }
    if (body is List<int>) {
      return Uint8List.fromList(body);
    }
    if (body is String) {
      return Uint8List.fromList(utf8.encode(body));
    }
    if (body is Map || body is List) {
      return Uint8List.fromList(utf8.encode(jsonEncode(body)));
    }
    throw UnsupportedError('不支援的簽章 body 型別：${body.runtimeType}');
  }

  /// 計算 body 的 SHA256 hex（小寫）。
  String bodySha256Hex(Object? body) {
    final bytes = normalizeBodyBytes(body);
    return sha256.convert(bytes).toString();
  }

  /// 產生 canonical string，須與後端完全一致。
  String canonicalString({
    required String method,
    required String path,
    required String query,
    required String nonce,
    required String timestamp,
    required String bodySha256,
    String version = 'v1',
  }) {
    final pathWithQuery = query.isEmpty ? path : '$path?$query';
    return [
      version,
      method.toUpperCase(),
      pathWithQuery,
      nonce,
      timestamp,
      bodySha256,
    ].join('\n');
  }

  /// 計算 HMAC-SHA256 digest bytes。
  Uint8List hmacSha256Digest({
    required Uint8List secret,
    required String message,
  }) {
    final mac = Hmac(sha256, secret);
    final digest = mac.convert(utf8.encode(message));
    return Uint8List.fromList(digest.bytes);
  }

  /// 計算簽章（hex 字串，對應後端 X-Signature）。
  String signatureHex({
    required Uint8List secret,
    required String message,
  }) {
    final digest = hmacSha256Digest(secret: secret, message: message);
    return _toHex(digest);
  }
}

String _toHex(List<int> bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}


