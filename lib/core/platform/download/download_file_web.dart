import 'package:web/web.dart' as web;

/// Web 平台下載：用 `<a download>` 直接觸發瀏覽器下載。
///
/// 使用 `package:web`（基於 `dart:js_interop`）取代 `dart:html`，避免 deprecated API。
Future<bool> downloadFile({
  required Uri uri,
  required String filename,
}) {
  try {
    // 若目前是 https 網站，但下載連結是 http，Chrome 會產生 internal redirect。
    // 某些情況下會影響下載行為（尤其搭配 `download` attribute / cache）。
    // 這裡在「頁面是 https」時，主動把下載連結升級成 https 以避免 307。
    final pageProtocol = web.window.location.protocol; // e.g. 'https:'
    var effectiveUri = uri;
    if (pageProtocol == 'https:' && uri.scheme == 'http') {
      effectiveUri = uri.replace(scheme: 'https');
    }

    // 加上 cache buster，避免瀏覽器把同一個下載視為「已完成」而沒有明顯下載動作。
    // 後端通常會忽略 query；即使不忽略，也不應影響檔案路徑解析。
    effectiveUri = effectiveUri.replace(
      queryParameters: {
        ...effectiveUri.queryParameters,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = effectiveUri.toString()
      ..download = filename
      ..style.display = 'none';

    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return Future.value(true);
  } catch (_) {
    return Future.value(false);
  }
}


