import 'package:flutter/material.dart';
import 'package:gait_charts/features/dashboard/domain/models/video_source.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_player_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/platform_video_player.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/video_player_controls.dart';

/// 全螢幕影片播放器。
///
/// 提供沉浸式的全螢幕播放體驗，支援鍵盤快捷鍵和滑鼠控制。
class VideoFullscreenPlayer extends StatelessWidget {
  const VideoFullscreenPlayer({
    required this.playerKey,
    required this.source,
    required this.sessionName,
    required this.playerState,
    required this.showControls,
    required this.focusNode,
    required this.onKeyEvent,
    required this.onStateChanged,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
    required this.onExitFullscreen,
    required this.onShowControlsChanged,
    super.key,
  });

  final GlobalKey<PlatformVideoPlayerState> playerKey;
  final VideoSource source;
  final String sessionName;
  final VideoPlayerState playerState;
  final bool showControls;
  final FocusNode focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent) onKeyEvent;
  final ValueChanged<VideoPlayerState> onStateChanged;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onExitFullscreen;
  final ValueChanged<bool> onShowControlsChanged;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: MouseRegion(
        onEnter: (_) => onShowControlsChanged(true),
        onExit: (_) => onShowControlsChanged(false),
        child: GestureDetector(
          onTap: () {
            focusNode.requestFocus();
            onTogglePlayPause();
          },
          onDoubleTap: onExitFullscreen,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 影片層
                Center(
                  child: PlatformVideoPlayer(
                    key: playerKey,
                    source: source,
                    onStateChanged: onStateChanged,
                    autoPlay: true,
                  ),
                ),

                // 緩衝指示器
                if (playerState.isBuffering)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // 中央播放按鈕
                if (playerState.isInitialized &&
                    !playerState.isPlaying &&
                    !playerState.isBuffering)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 80,
                        onPressed: onTogglePlayPause,
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white),
                      ),
                    ),
                  ),

                // Session 名稱（左上角）
                Positioned(
                  top: 24,
                  left: 24,
                  child: AnimatedOpacity(
                    opacity: showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.movie_outlined,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            sessionName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 退出全螢幕按鈕（右上角）
                Positioned(
                  top: 24,
                  right: 24,
                  child: AnimatedOpacity(
                    opacity: showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: onExitFullscreen,
                      icon: const Icon(Icons.fullscreen_exit_rounded,
                          color: Colors.white, size: 32),
                      tooltip: '退出全螢幕 (ESC)',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),

                // 控制列（底部）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: showControls || !playerState.isPlaying ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: VideoPlayerControls(
                      state: playerState,
                      onPlayPause: onTogglePlayPause,
                      onSeek: onSeek,
                      onVolumeChanged: onVolumeChanged,
                      onSpeedChanged: onSpeedChanged,
                      onFullscreen: onExitFullscreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
