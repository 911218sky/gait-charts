import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// 非 Web 平台：用 CookieJar 保存/回送 Set-Cookie。
///
/// 這裡用記憶體 CookieJar（不落地），避免在 Provider 建立 Dio 時引入 async 依賴。
/// 若未來需要跨重啟保留 Cookie，可再改成 PersistCookieJar + path_provider。
final CookieJar _cookieJar = CookieJar();

void configureDioCookieSupportImpl(Dio dio) {
  // 避免重複加入（例如 provider rebuild 建立新的 Dio）。
  final alreadyAdded = dio.interceptors.any((i) => i is CookieManager);
  if (alreadyAdded) return;

  dio.interceptors.add(CookieManager(_cookieJar));
}