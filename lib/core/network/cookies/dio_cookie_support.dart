import 'package:dio/dio.dart';

// Conditional import：
// - dart.library.io：Dart VM 平台（Android/iOS/Desktop/CLI）
// - dart.library.js_interop：Web 平台
//
// Web 交給瀏覽器管理 Cookie，非 Web 用 CookieJar 保存/回送 Set-Cookie
import 'dio_cookie_support_stub.dart'
    if (dart.library.io) 'dio_cookie_support_io.dart'
    if (dart.library.js_interop) 'dio_cookie_support_web.dart';

/// 設定 Dio 的 Cookie 支援。
/// Web 由瀏覽器管理，非 Web 使用 CookieJar。
void configureDioCookieSupport(Dio dio) {
  configureDioCookieSupportImpl(dio);
}

