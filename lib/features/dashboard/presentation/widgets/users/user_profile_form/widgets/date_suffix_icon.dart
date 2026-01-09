import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';

/// 日期欄位的後綴圖示：顯示日曆圖示，有值時可清除。
class DateSuffixIcon extends StatelessWidget {
  const DateSuffixIcon({
    super.key,
    required this.hasValue,
    required this.onClear,
    this.enabled = true,
  });

  final bool hasValue;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasValue)
          AppTooltip(
            message: '清除日期',
            child: IconButton(
              onPressed: enabled ? onClear : null,
              icon: Icon(Icons.close, size: 16, color: colors.onSurfaceVariant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        const SizedBox(width: 4),
        Icon(
          Icons.calendar_today,
          size: 16,
          color: enabled ? colors.onSurfaceVariant : colors.outlineVariant,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
