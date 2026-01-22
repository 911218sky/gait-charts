import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';

/// Dashboard Header 右側共用操作區：顯示目前 Session（以及可選的主題切換）。
///
/// 目的：避免多個 Header（analysis/heatmap/y-height/per-lap offset）重複同一段 UI。
class DashboardHeaderActions extends StatelessWidget {
  const DashboardHeaderActions({
    required this.activeSession,
    super.key,
    this.themeMode,
    this.onToggleTheme,
  });

  final String activeSession;
  final ThemeMode? themeMode;
  final VoidCallback? onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final showThemeToggle = themeMode != null && onToggleTheme != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showThemeToggle) ...[
          AppTooltip(
            message: '切換主題',
            child: IconButton(
              onPressed: onToggleTheme,
              icon: Icon(
                context.isDark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (activeSession.isNotEmpty)
          _ActiveSessionBadge(session: activeSession),
      ],
    );
  }
}

class _ActiveSessionBadge extends StatelessWidget {
  const _ActiveSessionBadge({required this.session});

  final String session;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目前 Session',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            session,
            style: textTheme.titleSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
