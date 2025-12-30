import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_player_provider.dart';

/// 影片播放控制列。
class VideoPlayerControls extends StatelessWidget {
  const VideoPlayerControls({
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
    super.key,
  });

  final VideoPlayerState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSpeedChanged;

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 進度條
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
          const SizedBox(height: 4),
          // 控制按鈕列
          Row(
            children: [
              // 播放/暫停
              IconButton(
                onPressed: state.isInitialized ? onPlayPause : null,
                icon: Icon(
                  state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // 時間顯示
              Text(
                '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              // 播放速度
              _SpeedSelector(
                currentSpeed: state.playbackSpeed,
                onSpeedChanged: onSpeedChanged,
              ),
              const SizedBox(width: 8),
              // 音量控制
              _VolumeControl(
                volume: state.volume,
                onVolumeChanged: onVolumeChanged,
              ),
            ],
          ),
        ],
      ),
    );
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
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              currentSpeed == 1.0 ? '1x' : '${currentSpeed}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_up, size: 16, color: Colors.white),
          ],
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
            icon: Icon(_volumeIcon, color: Colors.white, size: 24),
            tooltip: '靜音',
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _showSlider ? 80 : 0,
            child: _showSlider
                ? SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
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
