import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 播放器控制列的圖示按鈕。
class ControlIconButton extends StatelessWidget {
  const ControlIconButton({
    required this.onPressed,
    required this.icon,
    super.key,
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
        backgroundColor: isActive
            ? (context.isDark ? Colors.white : colors.primary)
            : Colors.transparent,
        foregroundColor: isActive
            ? (context.isDark ? Colors.black : Colors.white)
            : colors.onSurface,
        hoverColor: colors.onSurface.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
      ),
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
    );
  }
}

/// 播放器控制列的文字按鈕（圖示 + 標籤）。
class ControlTextButton extends StatelessWidget {
  const ControlTextButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    super.key,
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
    final color = isActive
        ? colors.primary
        : colors.onSurface.withValues(alpha: 0.7);

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
