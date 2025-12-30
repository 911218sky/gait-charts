import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/domain/models/video_source.dart';

/// 影片播放狀態。
@immutable
class VideoPlayerState {
  const VideoPlayerState({
    this.source,
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.errorMessage,
  });

  final VideoSource? source;
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final double playbackSpeed;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get hasSource => source != null;

  /// 播放進度（0.0 ~ 1.0）
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoPlayerState &&
        other.source?.uri == source?.uri &&
        other.isInitialized == isInitialized &&
        other.isPlaying == isPlaying &&
        other.isBuffering == isBuffering &&
        other.position == position &&
        other.duration == duration &&
        other.volume == volume &&
        other.playbackSpeed == playbackSpeed &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        source?.uri,
        isInitialized,
        isPlaying,
        isBuffering,
        position,
        duration,
        volume,
        playbackSpeed,
        errorMessage,
      );

  VideoPlayerState copyWith({
    VideoSource? source,
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? volume,
    double? playbackSpeed,
    String? errorMessage,
    bool clearError = false,
    bool clearSource = false,
  }) {
    return VideoPlayerState(
      source: clearSource ? null : (source ?? this.source),
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 是否為 Windows 平台（用於選擇播放器實作）。
bool get isWindowsPlatform {
  if (kIsWeb) return false;
  return Platform.isWindows;
}

/// 影片播放器狀態 Notifier。
class VideoPlayerNotifier extends Notifier<VideoPlayerState> {
  @override
  VideoPlayerState build() => const VideoPlayerState();

  void updateState(VideoPlayerState newState) {
    state = newState;
  }

  void reset() {
    state = const VideoPlayerState();
  }
}

/// 影片播放器狀態 Provider。
final videoPlayerStateProvider =
    NotifierProvider<VideoPlayerNotifier, VideoPlayerState>(
  VideoPlayerNotifier.new,
);
