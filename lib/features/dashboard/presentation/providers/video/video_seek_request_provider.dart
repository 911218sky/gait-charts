import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 影片跳轉請求。
///
/// 當從其他頁面（如分析頁面）需要跳轉到影片特定時間點時使用。
/// 設定後會被 VideoPlaybackView 消費並清除。
class VideoSeekRequest {
  const VideoSeekRequest({
    required this.targetSeconds,
  });

  /// 目標時間（秒）
  final double targetSeconds;

  Duration get targetDuration => Duration(
        milliseconds: (targetSeconds * 1000).round(),
      );
}

/// 管理影片跳轉請求的 Notifier。
class VideoSeekRequestNotifier extends Notifier<VideoSeekRequest?> {
  @override
  VideoSeekRequest? build() => null;

  /// 設定跳轉請求。
  void request(double targetSeconds) {
    state = VideoSeekRequest(targetSeconds: targetSeconds);
  }

  /// 清除跳轉請求（消費後呼叫）。
  void clear() {
    state = null;
  }
}

/// 影片跳轉請求 Provider。
final videoSeekRequestProvider =
    NotifierProvider<VideoSeekRequestNotifier, VideoSeekRequest?>(
  VideoSeekRequestNotifier.new,
);
