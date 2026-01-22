import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// 非 Web 平台：用 CookieJar 保存/回送 Set-Cookie。
/// 使用記憶體 CookieJar 避免 async 依賴，若需跨重啟保留可改用 PersistCookieJar。
final CookieJar _cookieJar = CookieJar();

void configureDioCookieSupportImpl(Dio dio) {
  // 避免 provider rebuild 時重複加入
  final alreadyAdded = dio.interceptors.any((i) => i is CookieManager);
  if (alreadyAdded) return;

  dio.interceptors.add(CookieManager(_cookieJar));
}