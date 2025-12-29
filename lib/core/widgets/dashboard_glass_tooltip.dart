import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 提供毛玻璃質感的 tooltip 容器，可放入任何自訂內容。
class DashboardGlassTooltip extends StatelessWidget {
  const DashboardGlassTooltip({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    // Tooltip 多半疊在圖表上：
    // - 深色模式：用「黑玻璃」＋白字（避免灰底黑字的突兀感）。
    // - 淺色模式：用「白玻璃」＋深字（更像現代 Vercel/Linear 風格）。
    final glassBase = isDark ? Colors.black : Colors.white;
    final g1 = glassBase.withValues(alpha: isDark ? 0.72 : 0.92);
    final g2 = glassBase.withValues(alpha: isDark ? 0.52 : 0.78);
    final border = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.10 : 0.08);
    final shadow = Colors.black.withValues(alpha: isDark ? 0.55 : 0.14);
    final fg = isDark ? Colors.white : Colors.black;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                g1,
                g2,
              ],
            ),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fg),
            child: IconTheme.merge(
              data: IconThemeData(color: fg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
