import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 展開/收合提示按鈕。
class ExpandHintTrailing extends StatelessWidget {
  const ExpandHintTrailing({
    required this.isExpanded,
    required this.borderColor,
    required this.labelColor,
    super.key,
  });

  final bool isExpanded;
  final Color borderColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        color: context.colorScheme.onSurface.withValues(alpha: 0.01),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isExpanded ? '收合' : '展開',
            style: context.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.expand_more, size: 18, color: labelColor),
          ),
        ],
      ),
    );
  }
}
