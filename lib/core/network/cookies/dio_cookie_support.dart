import 'package:dio/dio.dart';

// Dart 的 conditional import：
// - `dart.library.io`：代表在「Dart VM / 有 dart:io」的平台執行，通常包含：
//   - Android / iOS
//   - Windows / macOS / Linux（桌面）
//   - Dart CLI（命令列程式）
// - `dart.library.js_interop`：代表在「瀏覽器 Web」平台執行（有 dart:js_interop）。
//
// 這裡的策略：
// - Web：交給瀏覽器管理 Cookie（搭配 `withCredentials`）
// - 非 Web：用 CookieJar 保存/回送 `Set-Cookie`
import 'dio_cookie_support_stub.dart'
    if (dart.library.io) 'dio_cookie_support_io.dart'
    if (dart.library.js_interop) 'dio_cookie_support_web.dart';

/// 設定 Dio 的 Cookie 支援。
///
/// - Web：由瀏覽器自動管理 Cookie（配合 `withCredentials`）。
/// - 非 Web：使用 CookieJar 讓 Dio 能保存/回送 `Set-Cookie`。
void configureDioCookieSupport(Dio dio) {
  configureDioCookieSupportImpl(dio);
}

