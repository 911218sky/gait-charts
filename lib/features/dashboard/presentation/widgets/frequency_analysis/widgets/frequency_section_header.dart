import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';

/// 區段標題元件，左側帶有漸層色條裝飾
class FrequencySectionHeader extends StatelessWidget {
  const FrequencySectionHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    super.key,
  });

  final String title;
  final String subtitle;
  final DashboardAccentColors accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 32,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.success, accent.warning],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
