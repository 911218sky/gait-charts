import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:gait_charts/core/config/app_config.dart';

/// Dio interceptor：將 JSON request body gzip 壓縮成 bytes，並用 `application/octet-stream`
/// 送出（binary payload）。
///
/// - 只處理常見的 JSON body（Map/List/String/List<int>/Uint8List）。
/// - 送出時會將 `Content-Type` 設為 `application/octet-stream`，避免在 Web DevTools 直接顯示 JSON。
/// - 透過自訂 header 告知後端該如何還原：
///   - `X-Payload-Encoding: gzip`
///   - `X-Payload-Content-Type: application/json`
///
/// 注意：
/// - 這是「傳輸格式」調整，不是加密；有心人仍可解壓還原內容。
/// - Query string 仍會在 URL 中可見，無法透過此機制隱藏。
class RequestCompressionInterceptor extends Interceptor {
  RequestCompressionInterceptor({required this.config});

  final AppConfig config;

  static const String kHeaderPayloadEncoding = 'X-Payload-Encoding';
  static const String kHeaderPayloadContentType = 'X-Payload-Content-Type';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 如果未啟用壓縮，則直接跳過。
    if (!config.requestCompressionEnabled) {
      handler.next(options);
      return;
    }

    // 僅壓縮有 body 的 request，避免 GET/DELETE 等無意義處理。
    final method = options.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') {
      handler.next(options);
      return;
    }

    // 已經是 binary payload 就不再處理，避免 double gzip。
    final alreadyBinary = (options.headers[Headers.contentTypeHeader] ?? '')
        .toString()
        .toLowerCase()
        .contains('application/octet-stream');
    if (alreadyBinary || options.data is Uint8List) {
      handler.next(options);
      return;
    }

    // 嘗試將 body 轉換為 bytes。
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

    // 用 bytes 取代原本 data，並設定 Content-Encoding，讓後端知道要解壓。
    options.data = Uint8List.fromList(gz);
    // 設定 Content-Type 為 application/octet-stream，避免在 Web DevTools 直接顯示 JSON。
    options.headers[Headers.contentTypeHeader] = 'application/octet-stream';
    // 設定 X-Payload-Encoding 為 gzip，讓後端知道要解壓。
    options.headers[kHeaderPayloadEncoding] = 'gzip';
    // 設定 Content-Type 為 application/json，讓後端知道要還原為 JSON。
    options.headers[kHeaderPayloadContentType] = 'application/json';

    // Dio 對 bytes body 不一定會補 Content-Type；保留既有設定即可。
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


