import 'package:flutter/material.dart';
import 'package:gait_charts/features/dashboard/domain/models/video_source.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_player_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/platform_video_player.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/video_player_controls.dart';

/// 桌面版影片播放器區塊。
///
/// 包含影片播放器、控制列、Session 名稱顯示等。
/// 支援滑鼠 hover 顯示/隱藏控制列。
class VideoPlayerSection extends StatelessWidget {
  const VideoPlayerSection({
    required this.playerKey,
    required this.source,
    required this.sessionName,
    required this.playerState,
    required this.showControls,
    required this.onStateChanged,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
    required this.onFullscreen,
    required this.onShowControlsChanged,
    required this.onTap,
    super.key,
  });

  final GlobalKey<PlatformVideoPlayerState> playerKey;
  final VideoSource source;
  final String sessionName;
  final VideoPlayerState playerState;
  final bool showControls;
  final ValueChanged<VideoPlayerState> onStateChanged;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onFullscreen;
  final ValueChanged<bool> onShowControlsChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onShowControlsChanged(true),
      onExit: (_) => onShowControlsChanged(false),
      child: GestureDetector(
        onTap: () {
          onTap();
          onTogglePlayPause();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 影片層（支援縮放）
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PlatformVideoPlayer(
                      key: playerKey,
                      source: source,
                      onStateChanged: onStateChanged,
                      autoPlay: true,
                    ),
                  ),
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
                      iconSize: 64,
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
                  child: _SessionNameBadge(sessionName: sessionName),
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
                    onFullscreen: onFullscreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 手機版影片播放器區塊。
///
/// 全寬無圓角設計，類似 YouTube 的風格。
class MobileVideoPlayerSection extends StatelessWidget {
  const MobileVideoPlayerSection({
    required this.playerKey,
    required this.source,
    required this.sessionName,
    required this.playerState,
    required this.showControls,
    required this.onStateChanged,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
    required this.onFullscreen,
    required this.onShowControlsChanged,
    required this.onTap,
    super.key,
  });

  final GlobalKey<PlatformVideoPlayerState> playerKey;
  final VideoSource source;
  final String sessionName;
  final VideoPlayerState playerState;
  final bool showControls;
  final ValueChanged<VideoPlayerState> onStateChanged;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onFullscreen;
  final ValueChanged<bool> onShowControlsChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        onShowControlsChanged(!showControls);
      },
      onDoubleTap: onTogglePlayPause,
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
                    iconSize: 56,
                    onPressed: onTogglePlayPause,
                    icon:
                        const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ),
                ),
              ),

            // Session 名稱（左上角）
            Positioned(
              top: 12,
              left: 12,
              child: AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sessionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // 全螢幕按鈕（右上角）
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: onFullscreen,
                  icon: const Icon(Icons.fullscreen_rounded,
                      color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    minimumSize: const Size(44, 44),
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
                  onFullscreen: onFullscreen,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Session 名稱標籤。
class _SessionNameBadge extends StatelessWidget {
  const _SessionNameBadge({required this.sessionName});

  final String sessionName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            sessionName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
