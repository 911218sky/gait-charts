import 'package:flutter/material.dart';

/// 使用者標記（圓形）。
///
/// 用於在刻度條上標示使用者的數值位置。
/// 圓形設計搭配白色邊框和陰影，提供良好的視覺辨識度。
class UserMarker extends StatelessWidget {
  const UserMarker({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// 族群標記（菱形）。
///
/// 用於在刻度條上標示族群平均值的位置。
/// 菱形設計（45 度旋轉的正方形）與使用者標記區分。
class CohortMarker extends StatelessWidget {
  const CohortMarker({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398, // 45 度
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
