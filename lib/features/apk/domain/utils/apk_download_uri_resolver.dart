import 'package:gait_charts/features/apk/domain/models/apk_file.dart';

/// 解析 APK 下載連結。
///
/// 後端的 `url` 可能是：
/// - absolute URL：`https://api.example.com/apk/app.apk`
/// - root-relative：`/apk/app.apk`（常見於反向代理；需套用 baseUrl 的 host）
/// - relative：`apk/app.apk`（需相對於 baseUrl 的 path）
/// - empty：以前端規則自行組合 `baseUrl + /apk/{path}`
Uri resolveApkDownloadUri({
  required Uri base,
  required ApkFile file,
}) {
  final raw = file.url.trim();

  if (raw.isNotEmpty) {
    final parsed = Uri.parse(raw);
    // absolute（含 scheme）直接採用後端回傳
    if (parsed.hasScheme) return parsed;
    // relative（含 root-relative）則用 base 的 origin 進行 resolve
    return base.resolveUri(parsed);
  }

  // fallback：baseUrl + /apk/{file.path}
  final baseSegs = base.pathSegments.where((s) => s.isNotEmpty).toList();
  final fileSegs = file.path.split('/').where((s) => s.isNotEmpty).toList();
  return base.replace(pathSegments: [...baseSegs, 'apk', ...fileSegs]);
}


