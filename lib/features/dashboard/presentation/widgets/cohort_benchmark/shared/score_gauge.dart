import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 分數刻度條 - 視覺化顯示使用者在分數表上的位置。
///
/// 以漸層色帶呈現分數範圍，使用者位置以圓形標記顯示。
/// 參考值固定在中間位置，以垂直線標示。
///
/// 漸層方向根據 [higherIsBetter] 決定：
/// - `higherIsBetter = true`：左紅右綠（數值越大越好）
/// - `higherIsBetter = false`：左綠右紅（數值越小越好，如時間）
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    required this.userValue,
    required this.referenceValue,
    required this.statusColor,
    required this.higherIsBetter,
    this.cohortValue,
    this.height = 32,
    this.trackHeight = 6,
    this.markerSize = 12,
    super.key,
  });

  /// 使用者的數值
  final double userValue;

  /// 參考值（固定在刻度條中間）
  final double referenceValue;

  /// 狀態顏色（用於使用者標記）
  final Color statusColor;

  /// 數值越高是否越好
  /// - `true`：數值越大越好（如步頻）
  /// - `false`：數值越小越好（如時間）
  final bool higherIsBetter;

  /// 族群平均值（可選）
  final double? cohortValue;

  /// 刻度條總高度
  final double height;

  /// 軌道高度
  final double trackHeight;

  /// 標記大小
  final double markerSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    // 計算刻度範圍：以參考值為中心，左右各延伸 50%
    final minVal = referenceValue * 0.5;
    final maxVal = referenceValue * 1.5;
    final range = maxVal - minVal;

    // 計算使用者位置（0~1）
    final userPos =
        range > 0 ? ((userValue - minVal) / range).clamp(0.0, 1.0) : 0.5;

    // 漸層方向：higherIsBetter = false 時，左邊是好的（綠色）
    final leftIsBetter = !higherIsBetter;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final trackTop = (height - trackHeight) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 背景軌道（漸層）
              Positioned(
                left: 0,
                right: 0,
                top: trackTop,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                    gradient: LinearGradient(
                      colors: leftIsBetter
                          ? [
                              colors.tertiary.withValues(alpha: 0.3),
                              colors.primary.withValues(alpha: 0.3),
                              colors.error.withValues(alpha: 0.25),
                            ]
                          : [
                              colors.error.withValues(alpha: 0.25),
                              colors.primary.withValues(alpha: 0.3),
                              colors.tertiary.withValues(alpha: 0.3),
                            ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 參考值標記線（中間）
              Positioned(
                left: width * 0.5 - 1,
                top: trackTop - 4,
                child: Container(
                  width: 2,
                  height: trackHeight + 8,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),

              // 使用者標記（圓形）
              Positioned(
                left: (width * userPos - markerSize / 2).clamp(0, width - markerSize),
                top: (height - markerSize) / 2 - 2,
                child: Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 三角形繪製器。
///
/// 用於繪製指向特定位置的三角形標記，可作為刻度條上的指示器。
/// 支援自訂顏色、大小和方向。
class TrianglePainter extends CustomPainter {
  const TrianglePainter({
    required this.color,
    this.direction = TriangleDirection.down,
  });

  /// 三角形顏色
  final Color color;

  /// 三角形方向
  final TriangleDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (direction) {
      case TriangleDirection.up:
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
      case TriangleDirection.down:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width / 2, size.height);
      case TriangleDirection.left:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height / 2);
      case TriangleDirection.right:
        path.moveTo(0, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(0, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.direction != direction;
  }
}

/// 三角形方向。
enum TriangleDirection {
  /// 向上
  up,

  /// 向下
  down,

  /// 向左
  left,

  /// 向右
  right,
}

/// 三角形標記 Widget。
///
/// 封裝 [TrianglePainter]，提供便捷的三角形標記元件。
class TriangleMarker extends StatelessWidget {
  const TriangleMarker({
    required this.color,
    this.size = 8,
    this.direction = TriangleDirection.down,
    super.key,
  });

  /// 三角形顏色
  final Color color;

  /// 三角形大小（寬高相等）
  final double size;

  /// 三角形方向
  final TriangleDirection direction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: TrianglePainter(
        color: color,
        direction: direction,
      ),
    );
  }
}
