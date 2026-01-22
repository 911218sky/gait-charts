import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_player_provider.dart';

/// 影片播放控制列的顏色配置。
/// 
/// 影片播放器的控制列需要在影片上方顯示，因此無論淺色/深色模式，
/// 都使用深色風格（白色文字 + 黑色漸層背景），確保在影片上方清楚可見。
class _VideoControlColors {
  const _VideoControlColors._();

  static const foreground = Colors.white;
  static const foregroundMuted = Color(0xE6FFFFFF); // 90% white
  static const gradientEnd = Color(0xCC000000); // 80% black
  static const controlBackground = Color(0x26FFFFFF); // 15% white
  static const controlBorder = Color(0x33FFFFFF); // 20% white
}

/// 影片播放控制列。
class VideoPlayerControls extends StatelessWidget {
  const VideoPlayerControls({
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
    this.onFullscreen,
    this.compact = false,
    super.key,
  });

  final VideoPlayerState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback? onFullscreen;
  /// 是否使用緊湊模式（手機版）。
  final bool compact;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    
    // 緊湊模式（手機版）
    if (compact) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              _VideoControlColors.gradientEnd,
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 進度條
              SizedBox(
                height: 16,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: _VideoControlColors.foreground.withValues(alpha: 0.3),
                    thumbColor: colors.primary,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackShape: _CustomTrackShape(),
                  ),
                  child: Slider(
                    value: state.progress,
                    onChanged: state.isInitialized
                        ? (value) {
                            final newPosition = Duration(
                              milliseconds:
                                  (value * state.duration.inMilliseconds).round(),
                            );
                            onSeek(newPosition);
                          }
                        : null,
                  ),
                ),
              ),
              
              // 控制按鈕列（緊湊版）
              Row(
                children: [
                  // 播放/暫停
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: state.isInitialized ? onPlayPause : null,
                      icon: Icon(
                        state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: _VideoControlColors.foreground,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // 時間顯示
                  Text(
                    '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: _VideoControlColors.foregroundMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 播放速度（緊湊版）
                  _CompactSpeedSelector(
                    currentSpeed: state.playbackSpeed,
                    onSpeedChanged: onSpeedChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // 標準模式
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            _VideoControlColors.gradientEnd,
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 進度條
            SizedBox(
              height: 20,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: colors.primary,
                  inactiveTrackColor: _VideoControlColors.foreground.withValues(alpha: 0.3),
                  thumbColor: colors.primary,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  trackShape: _CustomTrackShape(),
                ),
                child: Slider(
                  value: state.progress,
                  onChanged: state.isInitialized
                      ? (value) {
                          final newPosition = Duration(
                            milliseconds:
                                (value * state.duration.inMilliseconds).round(),
                          );
                          onSeek(newPosition);
                        }
                      : null,
                ),
              ),
            ),
            
            // 控制按鈕列
            Row(
              children: [
                // 播放/暫停
                IconButton(
                  onPressed: state.isInitialized ? onPlayPause : null,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _VideoControlColors.foreground,
                    size: 28,
                  ),
                  tooltip: state.isPlaying ? '暫停 (Space)' : '播放 (Space)',
                ),
                
                const SizedBox(width: 8),
                
                // 時間顯示
                Text(
                  '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: _VideoControlColors.foregroundMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const Spacer(),
                
                // 播放速度
                _SpeedSelector(
                  currentSpeed: state.playbackSpeed,
                  onSpeedChanged: onSpeedChanged,
                ),
                
                const SizedBox(width: 4),
                
                // 音量控制
                _VolumeControl(
                  volume: state.volume,
                  onVolumeChanged: onVolumeChanged,
                ),

                const SizedBox(width: 4),
                
                // 全螢幕按鈕
                IconButton(
                   onPressed: onFullscreen,
                   icon: const Icon(Icons.fullscreen_rounded, color: _VideoControlColors.foreground),
                   tooltip: '全螢幕',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    Offset offset = Offset.zero,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight!;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

/// 播放速度選擇器。
class _SpeedSelector extends StatelessWidget {
  const _SpeedSelector({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: currentSpeed,
      onSelected: onSpeedChanged,
      tooltip: '播放速度',
      constraints: const BoxConstraints(minWidth: 100),
      position: PopupMenuPosition.over,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Colors.black.withValues(alpha: 0.9),
      itemBuilder: (context) => _speeds.map((speed) {
        final isSelected = speed == currentSpeed;
        return PopupMenuItem<double>(
          value: speed,
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Icon(Icons.check, size: 16, color: Colors.white)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                speed == 1.0 ? '1x（正常）' : '${speed}x',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _VideoControlColors.controlBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _VideoControlColors.controlBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed, size: 14, color: _VideoControlColors.foreground),
            const SizedBox(width: 6),
            Text(
              currentSpeed == 1.0 ? '1x' : '${currentSpeed}x',
              style: const TextStyle(
                color: _VideoControlColors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_up, size: 16, color: _VideoControlColors.foreground),
          ],
        ),
      ),
    );
  }
}

/// 緊湊版播放速度選擇器（手機版）。
class _CompactSpeedSelector extends StatelessWidget {
  const _CompactSpeedSelector({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: currentSpeed,
      onSelected: onSpeedChanged,
      tooltip: '播放速度',
      constraints: const BoxConstraints(minWidth: 80),
      position: PopupMenuPosition.over,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Colors.black.withValues(alpha: 0.9),
      itemBuilder: (context) => _speeds.map((speed) {
        final isSelected = speed == currentSpeed;
        return PopupMenuItem<double>(
          value: speed,
          height: 40,
          child: Text(
            speed == 1.0 ? '1x' : '${speed}x',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _VideoControlColors.controlBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          currentSpeed == 1.0 ? '1x' : '${currentSpeed}x',
          style: const TextStyle(
            color: _VideoControlColors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 音量控制。
class _VolumeControl extends StatefulWidget {
  const _VolumeControl({
    required this.volume,
    required this.onVolumeChanged,
  });

  final double volume;
  final ValueChanged<double> onVolumeChanged;

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  bool _showSlider = false;

  IconData get _volumeIcon {
    if (widget.volume == 0) return Icons.volume_off_rounded;
    if (widget.volume < 0.5) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _showSlider = true),
      onExit: (_) => setState(() => _showSlider = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              widget.onVolumeChanged(widget.volume > 0 ? 0 : 1);
            },
            icon: Icon(_volumeIcon, color: _VideoControlColors.foreground, size: 24),
            tooltip: '靜音',
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _showSlider ? 80 : 0,
            child: _showSlider
                ? SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: colors.primary,
                      inactiveTrackColor: _VideoControlColors.foreground.withValues(alpha: 0.3),
                      thumbColor: colors.primary,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: widget.volume,
                      onChanged: widget.onVolumeChanged,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
