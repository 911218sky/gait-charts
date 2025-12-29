import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

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
    final fps =
        widget.payload.meta.fpsOut <= 0 ? 24 : widget.payload.meta.fpsOut;
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
    final payload = widget.payload;
    final config = ref.watch(trajectoryPayloadConfigProvider);
    final overlayUi = ref.watch(trajectoryOverlayUiProvider);

    final fps = payload.meta.fpsOut <= 0 ? 24 : payload.meta.fpsOut;

    // 現代化播放器容器：深色圓角，無邊框
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: isDark ? 0 : 0.5)),
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
            painter: _TrajectoryPainter(
              payload: payload,
              playheadListenable: _playheadKNotifier,
              trailColor: colors.primary.withValues(alpha: 0.8),
              faintTrailColor:
                  colors.primary.withValues(alpha: 0.15),
              markerColor: isDark ? Colors.white : colors.onSurface,
              chairColor: accent.success,
              coneColor: accent.warning,
              gridColor: (isDark ? Colors.white : colors.onSurface).withValues(alpha: 0.05),
              axisColor: (isDark ? Colors.white : colors.onSurface).withValues(alpha: 0.3),
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
                        shadows: isDark ? [const Shadow(blurRadius: 4, color: Colors.black)] : null,
                      ),
                    ),
                    Text(
                      'Frame: $currentK / $_maxK',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        shadows: isDark ? const [Shadow(blurRadius: 2, color: Colors.black)] : null,
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
            child: _LegendOverlay(
              chairColor: accent.success,
              coneColor: accent.warning,
              markerColor: isDark ? Colors.white : colors.onSurface,
              trailColor: colors.primary,
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
                      color: isDark ? Colors.black.withValues(alpha: 0.6) : colors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.onSurface.withValues(alpha: isDark ? 0.1 : 0.08),
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
                                      enabledThumbRadius: 5), // 讓 thumb 小一點
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12),
                                  activeTrackColor: colors.primary,
                                  inactiveTrackColor: colors.onSurface.withValues(alpha: 0.12),
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
                        // Buttons Row
                        Row(
                          children: [
                            _ControlIconButton(
                              onPressed: _togglePlay,
                              icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              tooltip: _isPlaying ? '暫停' : '播放',
                              isActive: true,
                            ),
                            const SizedBox(width: 8),
                            _ControlIconButton(
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
                            _ControlTextButton(
                              onPressed: () => setState(() => _loop = !_loop),
                              icon: Icons.loop_rounded,
                              label: 'Loop',
                              isActive: _loop,
                            ),
                            const Spacer(),
                            // Rotate Button
                            _ControlTextButton(
                              onPressed: () {
                                ref
                                    .read(trajectoryPayloadConfigProvider.notifier)
                                    .updateRotate180(!config.rotate180);
                              },
                              icon: Icons.rotate_right_rounded,
                              label: 'Rotate',
                              isActive: config.rotate180,
                              tooltip: '旋轉 180° (需重新載入)',
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
                              offset: const Offset(0, -140), // 往上彈出
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: colors.outlineVariant.withValues(
                                    alpha: isDark ? 0.0 : 0.6,
                                  ),
                                ),
                              ),
                              onSelected: (v) => setState(() => _playbackSpeed = v),
                              itemBuilder: (context) => [0.25, 0.5, 1.0, 1.5, 2.0]
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
                                            fontWeight: s == _playbackSpeed ? FontWeight.bold : FontWeight.normal
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
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

/// 封裝統一風格的 Icon Button
class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.isActive = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? (context.isDark ? Colors.white : colors.primary) : Colors.transparent,
        foregroundColor: isActive ? (context.isDark ? Colors.black : Colors.white) : colors.onSurface,
        hoverColor: colors.onSurface.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
      ),
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
    );
  }
}

/// 封裝統一風格的 Text Button (Icon + Label)
class _ControlTextButton extends StatelessWidget {
  const _ControlTextButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isActive;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final color = isActive ? colors.primary : colors.onSurface.withValues(alpha: 0.7);
    
    return Tooltip(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendOverlay extends StatelessWidget {
  const _LegendOverlay({
    required this.chairColor,
    required this.coneColor,
    required this.markerColor,
    required this.trailColor,
  });

  final Color chairColor;
  final Color coneColor;
  final Color markerColor;
  final Color trailColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.6) : colors.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: isDark ? 0.1 : 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(
            icon: Icon(Icons.crop_square_rounded, size: 14, color: chairColor),
            label: 'Chair',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.change_history, size: 14, color: coneColor),
            label: 'Cone',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.timeline, size: 14, color: trailColor),
            label: 'Trajectory',
          ),
          const SizedBox(height: 12),
          Text(
            'Turn Markers',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
           _LegendItem(
            icon: Icon(Icons.circle_outlined, size: 14, color: coneColor),
            label: 'Start (Cone)',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.close, size: 14, color: coneColor),
            label: 'End (Cone)',
          ),
          const SizedBox(height: 6),
           _LegendItem(
            icon: _DiamondIcon(color: chairColor, size: 10),
            label: 'Start (Chair)',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.add, size: 14, color: chairColor),
            label: 'End (Chair)',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 16, height: 16, child: Center(child: icon)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DiamondIcon extends StatelessWidget {
  const _DiamondIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
        ),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({
    required this.payload,
    required this.playheadListenable,
    required this.trailColor,
    required this.faintTrailColor,
    required this.markerColor,
    required this.chairColor,
    required this.coneColor,
    required this.gridColor,
    required this.axisColor,
    required this.showChairArea,
    required this.showConeArea,
  })  : _faintPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = faintTrailColor,
        _solidPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = trailColor,
        _markerPaint = Paint()..color = markerColor,
        _axisPaint = Paint()
          ..color = axisColor
          ..strokeWidth = 1.5,
        _gridPaint = Paint()
          ..color = gridColor
          ..strokeWidth = 1.0,
        _borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = gridColor
          ..strokeWidth = 2,
        _textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
        ),
        super(repaint: playheadListenable);

  final TrajectoryDecodedPayload payload;
  final ValueListenable<double> playheadListenable;
  final Color trailColor;
  final Color faintTrailColor;
  final Color markerColor;
  final Color chairColor;
  final Color coneColor;
  final Color gridColor;
  final Color axisColor;
  final bool showChairArea;
  final bool showConeArea;

  // Paints/Text painter reuse避免每幀重建
  final Paint _faintPaint;
  final Paint _solidPaint;
  final Paint _markerPaint;
  final Paint _axisPaint;
  final Paint _gridPaint;
  final Paint _borderPaint;
  final TextPainter _textPainter;

  // 幾何快取，避免每幀重新算比例與全路徑
  static const double _padTop = 32.0;
  static const double _padBottom = 100.0;
  static const double _padH = 48.0;

  Size? _lastSize;
  TrajectoryDecodedPayload? _lastPayload;
  TrajectoryBounds? _bounds;
  double? _scale;
  double? _offsetX;
  double? _offsetY;
  Rect? _contentRect;
  Path? _faintPath;

  @override
  void paint(Canvas canvas, Size size) {
    if (payload.nFrames <= 0 || size.isEmpty) {
      return;
    }

    _ensureLayout(size);
    final currentK = playheadListenable.value.round().clamp(0, payload.nFrames - 1);
    final center = payload.centerXy;

    var currentLapIndex = -1;
    var lapStartK = 0;
    
    // 找出當前圈
    for (final lap in payload.laps) {
      if (lap.payloadStartK != null &&
          lap.payloadEndK != null &&
          currentK >= lap.payloadStartK! &&
          currentK <= lap.payloadEndK!) {
        currentLapIndex = lap.lapIndex;
        lapStartK = lap.payloadStartK!;
        break;
      }
    }

    // 1. 網格背景與座標軸
    _drawGridAndAxis(canvas);

    // 2. 完整路徑 (Faint) - 只算一次
    final faintPath = _faintPath;
    if (faintPath != null) {
      canvas.drawPath(faintPath, _faintPaint);
    }

    // 3. Active Trail (Current Lap Only)
    if (currentLapIndex != -1) {
      canvas.drawPath(
        _buildPath(
          center: center,
          startInclusive: lapStartK,
          endInclusive: currentK,
        ),
        _solidPaint,
      );
    }

    // 4. 場景物件 (Chair/Cone)
    _drawSceneObject(
      canvas: canvas,
      center: payload.sceneWorld.chair,
      radius: payload.sceneWorld.rChair,
      color: chairColor,
      icon: Icons.chair_alt, // 雖然 custom painter 不能直接畫 Icon, 但用形狀代替
      isSquare: true,
      showArea: showChairArea,
    );
    _drawSceneObject(
      canvas: canvas,
      center: payload.sceneWorld.cone,
      radius: payload.sceneWorld.rCone,
      color: coneColor,
      isSquare: false, // Triangle/Circle
      showArea: showConeArea,
    );

    // 5. Markers (Hip/Center/Pelvis)
    final i = currentK * 2;
    final pL = _toCanvas(payload.leftXy[i], payload.leftXy[i + 1]);
    final pR = _toCanvas(payload.rightXy[i], payload.rightXy[i + 1]);
    final pC = _toCanvas(center[i], center[i + 1]);

    // Pelvis Line
    canvas.drawLine(
      pL,
      pR,
      Paint()
        ..color = markerColor
        ..strokeWidth = 2.0,
    );
    // Dots
    canvas.drawCircle(pL, 4.0, _markerPaint);
    canvas.drawCircle(pR, 4.0, _markerPaint);
    canvas.drawCircle(pC, 5.0, _markerPaint); // Center slightly larger

    // 6. Turn Markers (Current Lap Only)
    if (currentLapIndex != -1) {
      final lap = payload.laps.firstWhere((l) => l.lapIndex == currentLapIndex);
      final m = lap.markers;
      
      void drawMark(int k, Color c, String type) {
        if (k < 0 || k >= payload.nFrames) return;
        final idx = k * 2;
        final p = _toCanvas(center[idx], center[idx + 1]);
        _drawMarkerShape(canvas, p, c, type);
      }

      if (m.coneStartK != null) drawMark(m.coneStartK!, coneColor, 'cone_start');
      if (m.coneEndK != null) drawMark(m.coneEndK!, coneColor, 'cone_end');
      if (m.chairStartK != null) drawMark(m.chairStartK!, chairColor, 'chair_start');
      if (m.chairEndK != null) drawMark(m.chairEndK!, chairColor, 'chair_end');
    }
  }

  void _ensureLayout(Size size) {
    if (_lastSize == size && identical(_lastPayload, payload)) {
      return;
    }

    _lastSize = size;
    _lastPayload = payload;
    _bounds = payload.meta.bounds;

    final bounds = _bounds!;
    final dx = bounds.dx;
    final dy = bounds.dy;

    final w = (size.width - _padH * 2).clamp(1.0, 1e12);
    final h = (size.height - _padTop - _padBottom).clamp(1.0, 1e12);

    final scale = (w / dx) < (h / dy) ? (w / dx) : (h / dy);
    _scale = scale;

    final contentW = dx * scale;
    final contentH = dy * scale;
    _offsetX = _padH + (w - contentW) * 0.5;
    _offsetY = _padTop + (h - contentH) * 0.5;
    _contentRect = Rect.fromLTWH(
      _padH,
      _padTop,
      size.width - _padH * 2,
      size.height - _padTop - _padBottom,
    );

    // cache faint path
    _faintPath = _buildPath(
      center: payload.centerXy,
      startInclusive: 0,
      endInclusive: payload.nFrames - 1,
    );
  }

  Offset _toCanvas(double x, double y) {
    final scale = _scale!;
    final bounds = _bounds!;
    final offsetX = _offsetX!;
    final offsetY = _offsetY!;
    final cx = offsetX + (x - bounds.xmin) * scale;
    final cy = offsetY + (bounds.ymax - y) * scale;
    return Offset(cx, cy);
  }

  Path _buildPath({
    required List<double> center,
    required int startInclusive,
    required int endInclusive,
  }) {
    final path = Path();
    if (startInclusive > endInclusive) return path;
    final first = _toCanvas(center[startInclusive * 2], center[startInclusive * 2 + 1]);
    path.moveTo(first.dx, first.dy);
    for (var k = startInclusive + 1; k <= endInclusive; k++) {
      final i = k * 2;
      final p = _toCanvas(center[i], center[i + 1]);
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  void _drawGridAndAxis(Canvas canvas) {
    final rect = _contentRect!;
    final bounds = _bounds!;
    final scale = _scale!;
    // Grid lines
    const stepPx = 50.0;
    for (var x = _padH; x < rect.right; x += stepPx) {
      canvas.drawLine(Offset(x, _padTop), Offset(x, rect.bottom), _gridPaint);
    }
    for (var y = _padTop; y < rect.bottom; y += stepPx) {
      canvas.drawLine(Offset(_padH, y), Offset(rect.right, y), _gridPaint);
    }

    // Border
    canvas.drawRect(rect, _borderPaint);

    void drawYAxis() {
      final worldHeight = rect.height / scale;
      final stepWorld = _niceStep(worldHeight / 6); // aim for ~6 ticks
      final startY = (bounds.ymin / stepWorld).ceil() * stepWorld;

      for (var y = startY; y <= bounds.ymax; y += stepWorld) {
        final cy = _offsetY! + (bounds.ymax - y) * scale;
        if (cy < rect.top || cy > rect.bottom) continue;

        canvas.drawLine(Offset(rect.left, cy), Offset(rect.left - 6, cy), _axisPaint);

        _textPainter.text = TextSpan(
          text: '${y.toStringAsFixed(1)}m',
          style: TextStyle(color: axisColor.withValues(alpha: 0.8), fontSize: 10),
        );
        _textPainter.layout();
        _textPainter.paint(
          canvas,
          Offset(rect.left - 8 - _textPainter.width, cy - _textPainter.height / 2),
        );
      }
    }

    void drawXAxis() {
      final worldWidth = rect.width / scale;
      final stepWorld = _niceStep(worldWidth / 8);
      final startX = (bounds.xmin / stepWorld).ceil() * stepWorld;

      for (var x = startX; x <= bounds.xmax; x += stepWorld) {
        final cx = _offsetX! + (x - bounds.xmin) * scale;
        if (cx < rect.left || cx > rect.right) continue;

        canvas.drawLine(Offset(cx, rect.bottom), Offset(cx, rect.bottom + 6), _axisPaint);

        _textPainter.text = TextSpan(
          text: '${x.toStringAsFixed(1)}m',
          style: TextStyle(color: axisColor.withValues(alpha: 0.8), fontSize: 10),
        );
        _textPainter.layout();
        _textPainter.paint(
          canvas,
          Offset(cx - _textPainter.width / 2, rect.bottom + 8),
        );
      }
    }

    drawYAxis();
    drawXAxis();
  }

  double _niceStep(double range) {
    final exponent = (log(range) / ln10).floor();
    final fraction = range / pow(10, exponent);
    double niceFraction;
    if (fraction < 1.5) {
      niceFraction = 1;
    } else if (fraction < 3) {
      niceFraction = 2;
    } else if (fraction < 7) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
    return niceFraction * pow(10, exponent);
  }

  void _drawSceneObject({
    required Canvas canvas,
    required Point<double> center,
    required double radius,
    required Color color,
    required bool showArea,
    bool isSquare = false,
    IconData? icon,
  }) {
    final c = _toCanvas(center.x, center.y);
    final r = (radius * (_scale ?? 1)).abs();

    if (showArea) {
      // Radius Circle
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.15);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.5);

      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, stroke);
    }

    // Center Shape
    final shapePaint = Paint()..color = color;
    if (isSquare) {
      canvas.drawRect(
        Rect.fromCenter(center: c, width: 14, height: 14),
        shapePaint,
      );
    } else {
      // Triangle
      final path = Path();
      path.moveTo(c.dx, c.dy - 8);
      path.lineTo(c.dx + 7, c.dy + 6);
      path.lineTo(c.dx - 7, c.dy + 6);
      path.close();
      canvas.drawPath(path, shapePaint);
    }
  }

  void _drawMarkerShape(Canvas canvas, Offset p, Color color, String type) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    // Glow
    canvas.drawCircle(
      p, 
      10, 
      Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.fill,
    );

    if (type.contains('cone')) {
      if (type.contains('start')) {
        // Circle
        canvas.drawCircle(p, 6, paint);
      } else {
        // X
        const d = 5.0;
        canvas.drawLine(p + const Offset(-d, -d), p + const Offset(d, d), paint);
        canvas.drawLine(p + const Offset(-d, d), p + const Offset(d, -d), paint);
      }
    } else {
      if (type.contains('start')) {
        // Diamond
        final path = Path();
        const d = 7.0;
        path.moveTo(p.dx, p.dy - d);
        path.lineTo(p.dx + d, p.dy);
        path.lineTo(p.dx, p.dy + d);
        path.lineTo(p.dx - d, p.dy);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Plus
        const d = 6.0;
        canvas.drawLine(p + const Offset(0, -d), p + const Offset(0, d), paint);
        canvas.drawLine(p + const Offset(-d, 0), p + const Offset(d, 0), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter oldDelegate) {
    return oldDelegate.payload != payload ||
        oldDelegate.trailColor != trailColor ||
        oldDelegate.faintTrailColor != faintTrailColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.chairColor != chairColor ||
        oldDelegate.coneColor != coneColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.playheadListenable != playheadListenable;
  }
}
