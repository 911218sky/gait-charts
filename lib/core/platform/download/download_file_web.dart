import 'package:web/web.dart' as web;

/// Web 平台下載：用 `<a download>` 觸發瀏覽器下載。
/// 使用 package:web 取代 dart:html 避免 deprecated API。
Future<bool> downloadFile({
  required Uri uri,
  required String filename,
}) {
  try {
    // https 頁面下載 http 連結時，Chrome 會產生 internal redirect
    // 主動升級成 https 避免 307
    final pageProtocol = web.window.location.protocol; // e.g. 'https:'
    var effectiveUri = uri;
    if (pageProtocol == 'https:' && uri.scheme == 'http') {
      effectiveUri = uri.replace(scheme: 'https');
    }

    // 加上 cache buster 避免瀏覽器把同一個下載視為已完成
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


