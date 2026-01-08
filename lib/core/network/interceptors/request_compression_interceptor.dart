import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:gait_charts/core/config/app_config.dart';

/// 將 JSON request body gzip 壓縮後以 binary 送出。
///
/// 處理 Map/List/String/bytes 類型的 body，設定以下 headers：
/// - Content-Type: application/octet-stream
/// - X-Payload-Encoding: gzip
/// - X-Payload-Content-Type: application/json
///
/// 這是傳輸格式調整而非加密，Query string 仍在 URL 中可見。
class RequestCompressionInterceptor extends Interceptor {
  RequestCompressionInterceptor({required this.config});

  final AppConfig config;

  static const String kHeaderPayloadEncoding = 'X-Payload-Encoding';
  static const String kHeaderPayloadContentType = 'X-Payload-Content-Type';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 未啟用壓縮則跳過
    if (!config.requestCompressionEnabled) {
      handler.next(options);
      return;
    }

    // 僅壓縮有 body 的 request
    final method = options.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') {
      handler.next(options);
      return;
    }

    // 已是 binary payload 則不再處理，避免 double gzip
    final alreadyBinary = (options.headers[Headers.contentTypeHeader] ?? '')
        .toString()
        .toLowerCase()
        .contains('application/octet-stream');
    if (alreadyBinary || options.data is Uint8List) {
      handler.next(options);
      return;
    }

    // 嘗試將 body 轉為 bytes
    final bodyBytes = _tryBodyToBytes(options.data);
    if (bodyBytes == null || bodyBytes.isEmpty) {
      handler.next(options);
      return;
    }

    // gzip 壓縮
    final gz = const GZipEncoder().encode(bodyBytes);
    if (gz.isEmpty) {
      handler.next(options);
      return;
    }

    // 用壓縮後的 bytes 取代原本 data
    options.data = Uint8List.fromList(gz);
    options.headers[Headers.contentTypeHeader] = 'application/octet-stream';
    options.headers[kHeaderPayloadEncoding] = 'gzip';
    options.headers[kHeaderPayloadContentType] = 'application/json';

    // Dio 對 bytes body 不一定會補 Content-Type，保留既有設定即可
    handler.next(options);
  }
}

List<int>? _tryBodyToBytes(Object? data) {
  if (data == null) return const <int>[];
  if (data is Uint8List) return data;
  if (data is List<int>) return data;
  if (data is String) return utf8.encode(data);
  if (data is Map || data is List) {
    // 對齊 dio 的 JSON encode 行為：用 jsonEncode + UTF8。
    return utf8.encode(jsonEncode(data));
  }
  // FormData / Stream / 其他不處理：避免壓縮後後端不知如何還原。
  return null;
}


