import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/trajectory/trajectory_player/trajectory_player.dart';

/// 軌跡播放器：現代化 UI 風格。
/// 包含 Canvas 繪圖區與底部懸浮控制列。
class TrajectoryPlayerCard extends ConsumerStatefulWidget {
  const TrajectoryPlayerCard({required this.payload, super.key});

  final TrajectoryDecodedPayload payload;

  @override
  ConsumerState<TrajectoryPlayerCard> createState() =>
      _TrajectoryPlayerCardState();
}

class _TrajectoryPlayerCardState extends ConsumerState<TrajectoryPlayerCard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastTick;
  late final ValueNotifier<double> _playheadKNotifier;

  bool _isPlaying = false;
  bool _loop = true;
  double _playbackSpeed = 1.0;

  int get _maxK => (widget.payload.nFrames - 1).clamp(0, 1 << 30);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _playheadKNotifier = ValueNotifier<double>(0);
  }

  @override
  void didUpdateWidget(covariant TrajectoryPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload != widget.payload) {
      _lastTick = null;
      _playheadKNotifier.value = 0.0;
      _isPlaying = false;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _playheadKNotifier.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying) {
      _lastTick = elapsed;
      return;
    }
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) {
      return;
    }
    final dt = (elapsed - last).inMicroseconds / 1e6;
    final fps = widget.payload.meta.fpsOut <= 0
        ? 24
        : widget.payload.meta.fpsOut;
    final next = _playheadKNotifier.value + dt * fps * _playbackSpeed;

    if (next >= _maxK) {
      if (_loop) {
        _playheadKNotifier.value = 0.0;
      } else {
        setState(() {
          _isPlaying = false;
        });
        _playheadKNotifier.value = _maxK.toDouble();
        _ticker.stop();
      }
      return;
    }

    _playheadKNotifier.value = next;
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _lastTick = null;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  void _seekTo(double k) {
    _playheadKNotifier.value = k.clamp(0.0, _maxK.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final accent = DashboardAccentColors.of(context);
    final heatmapPalette = DashboardHeatmapPalette.of(context);
    final payload = widget.payload;
    final config = ref.watch(trajectoryPayloadConfigProvider);
    final overlayUi = ref.watch(trajectoryOverlayUiProvider);
    final overlayNotifier = ref.read(trajectoryOverlayUiProvider.notifier);

    final fps = payload.meta.fpsOut <= 0 ? 24 : payload.meta.fpsOut;

    // 現代化播放器容器：深色圓角，無邊框
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Canvas Layer
          CustomPaint(
            isComplex: true,
            willChange: true,
            painter: TrajectoryPainter(
              payload: payload,
              playheadListenable: _playheadKNotifier,
              trailColor: colors.primary.withValues(alpha: 0.8), // fallback
              markerColor: isDark ? Colors.white : colors.onSurface,
              chairColor: accent.success,
              coneColor: accent.warning,
              gridColor: (isDark ? Colors.white : colors.onSurface).withValues(
                alpha: 0.05,
              ),
              axisColor: (isDark ? Colors.white : colors.onSurface).withValues(
                alpha: 0.3,
              ),
              heatmapColors: heatmapPalette.colors,
              showFullTrail: overlayUi.showFullTrail,
              showChairArea: overlayUi.showChairArea,
              showConeArea: overlayUi.showConeArea,
            ),
          ),

          // 2. Info Overlay (Top Left)
          Positioned(
            top: 20,
            left: 24,
            child: ValueListenableBuilder<double>(
              valueListenable: _playheadKNotifier,
              builder: (context, v, _) {
                final currentK = v.round().clamp(0, _maxK);
                final timeS = currentK / fps;
                final totalS = _maxK / fps;

                String fmtTime(double s) {
                  final m = (s ~/ 60).toString().padLeft(2, '0');
                  final sec = (s % 60).toInt().toString().padLeft(2, '0');
                  return '$m:$sec';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fmtTime(timeS)} / ${fmtTime(totalS)}',
                      style: TextStyle(
                        color: isDark ? Colors.white : colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: isDark
                            ? [const Shadow(blurRadius: 4, color: Colors.black)]
                            : null,
                      ),
                    ),
                    Text(
                      'Frame: $currentK / $_maxK',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        shadows: isDark
                            ? const [Shadow(blurRadius: 2, color: Colors.black)]
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. Legend Overlay (Top Right)
          Positioned(
            top: 20,
            right: 24,
            child: LegendOverlay(
              chairColor: accent.success,
              coneColor: accent.warning,
              markerColor: isDark ? Colors.white : colors.onSurface,
              heatmapColors: heatmapPalette.colors,
            ),
          ),

          // 4. Controls Overlay (Bottom) - 現代化毛玻璃風格
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : colors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.onSurface.withValues(
                          alpha: isDark ? 0.1 : 0.08,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Bar
                        SizedBox(
                          height: 24,
                          child: ValueListenableBuilder<double>(
                            valueListenable: _playheadKNotifier,
                            builder: (context, v, _) {
                              return SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3, // 讓軌道細一點
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ), // 讓 thumb 小一點
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  activeTrackColor: colors.primary,
                                  inactiveTrackColor: colors.onSurface
                                      .withValues(alpha: 0.12),
                                  thumbColor: colors.primary,
                                ),
                                child: Slider(
                                  value: v,
                                  min: 0,
                                  max: _maxK.toDouble().clamp(0.0, 1e12),
                                  onChanged: (nv) {
                                    // 尋找時保持播放不中斷，重設 lastTick 避免下一幀跳躍
                                    if (_isPlaying) {
                                      _lastTick = null;
                                    }
                                    _seekTo(nv);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Buttons Row - 響應式佈局
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 400;
                            
                            if (isNarrow) {
                              // 窄螢幕：分兩行顯示
                              return Column(
                                children: [
                                  // 第一行：播放控制
                                  Row(
                                    children: [
                                      ControlIconButton(
                                        onPressed: _togglePlay,
                                        icon: _isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        tooltip: _isPlaying ? '暫停' : '播放',
                                        isActive: true,
                                      ),
                                      const SizedBox(width: 8),
                                      ControlIconButton(
                                        onPressed: () {
                                          _ticker.stop();
                                          setState(() {
                                            _isPlaying = false;
                                          });
                                          _playheadKNotifier.value = 0.0;
                                        },
                                        icon: Icons.replay_rounded,
                                        tooltip: '重播',
                                      ),
                                      const SizedBox(width: 12),
                                      ControlTextButton(
                                        onPressed: () => setState(() => _loop = !_loop),
                                        icon: Icons.loop_rounded,
                                        label: 'Loop',
                                        isActive: _loop,
                                      ),
                                      const Spacer(),
                                      // Speed Menu
                                      PopupMenuButton<double>(
                                        initialValue: _playbackSpeed,
                                        tooltip: '播放速度',
                                        color: isDark
                                            ? const Color(0xFF2C2C2C)
                                            : colors.surface,
                                        surfaceTintColor: Colors.transparent,
                                        offset: const Offset(0, -140),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(
                                            color: colors.outlineVariant.withValues(
                                              alpha: isDark ? 0.0 : 0.6,
                                            ),
                                          ),
                                        ),
                                        onSelected: (v) =>
                                            setState(() => _playbackSpeed = v),
                                        itemBuilder: (context) =>
                                            [0.25, 0.5, 1.0, 1.5, 2.0]
                                                .map(
                                                  (s) => PopupMenuItem(
                                                    value: s,
                                                    height: 36,
                                                    child: Text(
                                                      '${s}x',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : colors.onSurface,
                                                        fontWeight: s == _playbackSpeed
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : colors.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: colors.outlineVariant.withValues(
                                                alpha: isDark ? 0.0 : 0.6,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '${_playbackSpeed}x',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : colors.onSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // 第二行：顯示選項
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ControlTextButton(
                                        onPressed: () {
                                          ref
                                              .read(
                                                trajectoryPayloadConfigProvider.notifier,
                                              )
                                              .updateRotate180(!config.rotate180);
                                        },
                                        icon: Icons.rotate_right_rounded,
                                        label: 'Rotate',
                                        isActive: config.rotate180,
                                        tooltip: '旋轉 180° (需重新載入)',
                                      ),
                                      const SizedBox(width: 12),
                                      ControlTextButton(
                                        onPressed: () => overlayNotifier.toggleFullTrail(
                                          !overlayUi.showFullTrail,
                                        ),
                                        icon: Icons.timeline_rounded,
                                        label: overlayUi.showFullTrail ? 'Full' : 'Lap',
                                        isActive: overlayUi.showFullTrail,
                                        tooltip: overlayUi.showFullTrail
                                            ? '顯示全部軌跡（從開始→目前 frame，新→舊熱力圖）'
                                            : '只顯示當圈軌跡（新→舊熱力圖）',
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            
                            // 寬螢幕：單行顯示
                            return Row(
                              children: [
                                ControlIconButton(
                                  onPressed: _togglePlay,
                                  icon: _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  tooltip: _isPlaying ? '暫停' : '播放',
                                  isActive: true,
                                ),
                                const SizedBox(width: 8),
                                ControlIconButton(
                                  onPressed: () {
                                    _ticker.stop();
                                    setState(() {
                                      _isPlaying = false;
                                    });
                                    _playheadKNotifier.value = 0.0;
                                  },
                                  icon: Icons.replay_rounded,
                                  tooltip: '重播',
                                ),
                                const SizedBox(width: 16),
                                // Loop Toggle
                                ControlTextButton(
                                  onPressed: () => setState(() => _loop = !_loop),
                                  icon: Icons.loop_rounded,
                                  label: 'Loop',
                                  isActive: _loop,
                                ),
                                const Spacer(),
                                // Rotate Button
                                ControlTextButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          trajectoryPayloadConfigProvider.notifier,
                                        )
                                        .updateRotate180(!config.rotate180);
                                  },
                                  icon: Icons.rotate_right_rounded,
                                  label: 'Rotate',
                                  isActive: config.rotate180,
                                  tooltip: '旋轉 180° (需重新載入)',
                                ),
                                const SizedBox(width: 12),
                                ControlTextButton(
                                  onPressed: () => overlayNotifier.toggleFullTrail(
                                    !overlayUi.showFullTrail,
                                  ),
                                  icon: Icons.timeline_rounded,
                                  label: overlayUi.showFullTrail ? 'Full' : 'Lap',
                                  isActive: overlayUi.showFullTrail,
                                  tooltip: overlayUi.showFullTrail
                                      ? '顯示全部軌跡（從開始→目前 frame，新→舊熱力圖）'
                                      : '只顯示當圈軌跡（新→舊熱力圖）',
                                ),
                                const SizedBox(width: 12),
                                // Speed Menu
                                PopupMenuButton<double>(
                                  initialValue: _playbackSpeed,
                                  tooltip: '播放速度',
                                  color: isDark
                                      ? const Color(0xFF2C2C2C)
                                      : colors.surface,
                                  surfaceTintColor: Colors.transparent,
                                  offset: const Offset(0, -140),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: colors.outlineVariant.withValues(
                                        alpha: isDark ? 0.0 : 0.6,
                                      ),
                                    ),
                                  ),
                                  onSelected: (v) =>
                                      setState(() => _playbackSpeed = v),
                                  itemBuilder: (context) =>
                                      [0.25, 0.5, 1.0, 1.5, 2.0]
                                          .map(
                                            (s) => PopupMenuItem(
                                              value: s,
                                              height: 36,
                                              child: Text(
                                                '${s}x',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : colors.onSurface,
                                                  fontWeight: s == _playbackSpeed
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : colors.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: colors.outlineVariant.withValues(
                                          alpha: isDark ? 0.0 : 0.6,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_playbackSpeed}x',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : colors.onSurface,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
