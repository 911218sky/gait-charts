import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Web：由瀏覽器管理 Cookie。
/// 開發模式下啟用 withCredentials 以支援跨站請求帶 Cookie。
void configureDioCookieSupportImpl(Dio dio) {
  if (!kDebugMode) return;

  final adapter = dio.httpClientAdapter;
  if (adapter is BrowserHttpClientAdapter) {
    adapter.withCredentials = true;
  }
}