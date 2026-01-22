import 'package:url_launcher/url_launcher.dart';

/// 非 Web 平台下載：交給系統外部應用處理（通常是瀏覽器）。
Future<bool> downloadFile({
  required Uri uri,
  required String filename,
}) async {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}


