/// Stub：非 io / 非 web 平台的 no-op。
/// 正常情況不應執行到這裡，若觸發代表平台不支援或 conditional import 未生效。
Future<bool> downloadFile({
  required Uri uri,
  required String filename,
}) async {
  return false;
}


