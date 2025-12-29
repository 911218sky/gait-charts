/// 下載產物的目標平台分類。
///
/// 注意：
/// - 後端 `/apk` 允許回傳任意檔案，因此前端需要自行依檔名/副檔名做分類。
/// - 這個 enum 放在 domain 層，避免 UI 到處寫字串判斷。
enum ApkArtifactPlatform {
  android,
  windows,
  macos,
  linux,
  unknown,
}

extension ApkArtifactPlatformX on ApkArtifactPlatform {
  /// 用於 UI 顯示的標題（繁中 + 技術名詞）。
  String get displayLabel {
    switch (this) {
      case ApkArtifactPlatform.android:
        return 'Android（APK）';
      case ApkArtifactPlatform.windows:
        return 'Windows';
      case ApkArtifactPlatform.macos:
        return 'macOS';
      case ApkArtifactPlatform.linux:
        return 'Linux';
      case ApkArtifactPlatform.unknown:
        return '其他';
    }
  }
}


