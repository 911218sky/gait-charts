import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Web：由瀏覽器自動管理 Cookie。
///
/// 若要讓瀏覽器在「跨站（不同網域/port）」請求也能帶上 Cookie，
/// 必須把 XHR/fetch 設成 `withCredentials = true`（同時後端也要允許 credentials）。
void configureDioCookieSupportImpl(Dio dio) {
  final adapter = dio.httpClientAdapter;
  if (adapter is BrowserHttpClientAdapter) {
    adapter.withCredentials = true;
  }
}