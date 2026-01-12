import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';

/// 頻率分析區塊的空狀態顯示
class FrequencyEmptyState extends StatelessWidget {
  const FrequencyEmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        color: colors.surface,
      ),
      child: Text(
        message,
        style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
