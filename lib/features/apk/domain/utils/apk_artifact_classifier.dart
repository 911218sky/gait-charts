import 'package:gait_charts/features/apk/domain/models/apk_artifact_platform.dart';

/// 依檔名推斷下載產物的平台分類。
///
/// 規則優先序：
/// 1) 明確副檔名（.apk/.exe/.msi/.dmg/.pkg/.tar.gz/.tgz/.appimage）
/// 2) 檔名關鍵字（macos/linux/windows/arm64-v8a 等）
ApkArtifactPlatform classifyApkArtifactPlatform(String filename) {
  final name = filename.trim().toLowerCase();
  if (name.isEmpty) return ApkArtifactPlatform.unknown;

  // 明確副檔名優先
  if (name.endsWith('.apk')) return ApkArtifactPlatform.android;

  if (name.endsWith('.exe') || name.endsWith('.msi')) {
    return ApkArtifactPlatform.windows;
  }

  if (name.endsWith('.dmg') || name.endsWith('.pkg')) {
    return ApkArtifactPlatform.macos;
  }

  // Linux 常見封裝
  if (name.endsWith('.tar.gz') || name.endsWith('.tgz') || name.endsWith('.appimage')) {
    return ApkArtifactPlatform.linux;
  }

  // .zip 可能是 macOS 或其他平台，先靠關鍵字
  if (name.endsWith('.zip')) {
    if (_hasMacKeyword(name)) return ApkArtifactPlatform.macos;
    if (_hasWindowsKeyword(name)) return ApkArtifactPlatform.windows;
    if (_hasLinuxKeyword(name)) return ApkArtifactPlatform.linux;
  }

  // 關鍵字 fallback（例如：GaitCharts-macOS.zip / GaitCharts-Linux-x64.tar.gz）
  if (_hasLinuxKeyword(name)) return ApkArtifactPlatform.linux;
  if (_hasMacKeyword(name)) return ApkArtifactPlatform.macos;
  if (_hasWindowsKeyword(name)) return ApkArtifactPlatform.windows;

  // Android ABI 關鍵字（通常仍是 .apk，但保險起見）
  if (name.contains('arm64-v8a') ||
      name.contains('armeabi-v7a') ||
      name.contains('x86_64') ||
      name.contains('universal')) {
    return ApkArtifactPlatform.android;
  }

  return ApkArtifactPlatform.unknown;
}

bool _hasMacKeyword(String name) =>
    name.contains('macos') || name.contains('osx') || name.contains('mac');

bool _hasLinuxKeyword(String name) => name.contains('linux');

bool _hasWindowsKeyword(String name) =>
    name.contains('windows') || name.contains('win');


