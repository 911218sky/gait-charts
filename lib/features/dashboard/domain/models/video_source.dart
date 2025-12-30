import 'package:flutter/foundation.dart';

/// 影片來源類型。
enum VideoSourceType {
  /// 網路串流（後端 API）
  network,
  /// 本機檔案
  file,
}

/// 影片來源資訊。
@immutable
class VideoSource {
  const VideoSource({
    required this.type,
    required this.uri,
    this.sessionName,
  });

  final VideoSourceType type;
  final String uri;
  /// 關聯的 session 名稱（若有）
  final String? sessionName;

  /// 從 session 建立網路影片來源。
  factory VideoSource.fromSession({
    required String baseUrl,
    required String sessionName,
  }) {
    // 移除 baseUrl 結尾的斜線
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = '$normalizedBase/realsense_pose_extractor/sessions/$sessionName/video';
    return VideoSource(
      type: VideoSourceType.network,
      uri: uri,
      sessionName: sessionName,
    );
  }

  /// 從本機檔案路徑建立。
  factory VideoSource.fromFile(String path) {
    return VideoSource(
      type: VideoSourceType.file,
      uri: path,
    );
  }
}
