import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 新手提示框，點擊可開啟完整說明。
class BeginnerHelpBox extends StatelessWidget {
  const BeginnerHelpBox({
    required this.accent,
    required this.onOpenFullHelp,
    super.key,
  });

  final DashboardAccentColors accent;
  final VoidCallback onOpenFullHelp;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    return InkWell(
      onTap: onOpenFullHelp,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.04),
          border: Border.all(color: context.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: accent.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '遇到困難？查看 FFT 參數白話說明',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
