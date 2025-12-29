import 'package:meta/meta.dart';

import 'package:gait_charts/features/apk/domain/models/apk_file.dart';

/// 後端 `/apk` 回傳的檔案清單。
@immutable
class ApkFileListResponse {
  const ApkFileListResponse({
    required this.baseDir,
    required this.files,
  });

  /// 後端的 APK 目錄（用於除錯/顯示，不作為 UI 必要資訊）。
  final String baseDir;

  final List<ApkFile> files;

  factory ApkFileListResponse.fromJson(Map<String, dynamic> json) {
    final baseDir = (json['base_dir']?.toString() ?? '').trim();
    final rawFiles = json['files'];

    final files = <ApkFile>[];
    if (rawFiles is List) {
      for (final item in rawFiles) {
        if (item is Map<String, dynamic>) {
          files.add(ApkFile.fromJson(item));
          continue;
        }
        if (item is Map) {
          files.add(
            ApkFile.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return ApkFileListResponse(
      baseDir: baseDir,
      files: files,
    );
  }
}


