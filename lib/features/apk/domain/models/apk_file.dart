/// 單一安裝包檔案（通常為 `.apk`，但後端允許任意檔案）。
class ApkFile {
  const ApkFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.url,
  });

  /// 相對於後端 APK 目錄的路徑（可含子資料夾，例如 `builds/app.apk`）。
  final String path;

  /// 檔名（`path` 的最後一段）。
  final String name;

  /// 檔案大小（bytes）。
  final int sizeBytes;

  /// 修改時間（UTC）。
  final DateTime modifiedAt;

  /// 後端回傳的下載連結；可能為 absolute URL。
  ///
  /// 若後端未提供或不可信任，前端可用 baseUrl + `/apk/{path}` 自行組出下載連結。
  final String url;

  factory ApkFile.fromJson(Map<String, dynamic> json) {
    final path = (json['path']?.toString() ?? '').trim();
    final name = (json['name']?.toString() ?? '').trim();

    final sizeRaw = json['size_bytes'];
    final size = switch (sizeRaw) {
      final int v => v,
      final num v => v.toInt(),
      _ => int.tryParse(sizeRaw?.toString() ?? '') ?? 0,
    };

    // 後端以 unix seconds 回傳（int）。
    final mtimeRaw = json['mtime'];
    final mtimeSeconds = switch (mtimeRaw) {
      final int v => v,
      final num v => v.toInt(),
      _ => int.tryParse(mtimeRaw?.toString() ?? '') ?? 0,
    };
    final modifiedAt = DateTime.fromMillisecondsSinceEpoch(
      mtimeSeconds * 1000,
      isUtc: true,
    );

    final url = (json['url']?.toString() ?? '').trim();

    return ApkFile(
      path: path,
      name: name.isNotEmpty ? name : (path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? path),
      sizeBytes: size < 0 ? 0 : size,
      modifiedAt: modifiedAt,
      url: url,
    );
  }
}

extension on Iterable<String> {
  String? get lastOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    var last = it.current;
    while (it.moveNext()) {
      last = it.current;
    }
    return last;
  }
}


