import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';

/// 簡易 session 卡片，用於 session 選擇面板。
class SimpleSessionCard extends StatelessWidget {
  const SimpleSessionCard({
    required this.sessionName,
    required this.bagPath,
    required this.bagFilename,
    required this.createdAt,
    required this.onTap,
    super.key,
  });

  final String sessionName;
  final String bagPath;
  final String bagFilename;
  final DateTime createdAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Material(
      color: context.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colors.onSurface.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.description_outlined, size: 18, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                sessionName,
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                bagFilename,
                style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${createdAt.toLocal()}'.split('.').first,
                style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
