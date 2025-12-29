/// 跨平台檔案下載工具（platform 層）。
///
/// - Web：使用 HTML anchor 觸發瀏覽器原生下載（避免被 popup blocker 擋掉）。
/// - 非 Web：交給系統外部應用處理（通常是瀏覽器）。
export 'download_file_stub.dart'
    if (dart.library.js_interop) 'download_file_web.dart'
    if (dart.library.io) 'download_file_io.dart';


