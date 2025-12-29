import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';

/// 頻譜分析頁面的標題區塊，包含 Session 選擇與載入控制
class FrequencyAnalysisHeader extends ConsumerWidget {
  const FrequencyAnalysisHeader({
    required this.sessionController,
    required this.onLoadSession,
    required this.onBrowseSessions,
    required this.isLoading,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;
  final VoidCallback onBrowseSessions;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final activeSession = ref.watch(activeSessionProvider);
    final textTheme = context.textTheme;

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          return Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '頻譜分析',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '觀察空間軌跡與多關節訊號在頻域的表現，協助辨識震盪與步態異常。',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isCompact)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: SessionAutocompleteField(
                          controller: sessionController,
                          labelText: 'Session 名稱',
                          hintText: 'patient_2025_1101',
                          enabled: !isLoading,
                          onSubmitted: isLoading ? null : (_) => onLoadSession(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : onBrowseSessions,
                        icon: const Icon(Icons.search),
                        label: const Text('瀏覽 Sessions'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: isLoading ? null : onLoadSession,
                        icon: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.analytics_outlined),
                        label: Text(isLoading ? '載入中' : '載入頻譜'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SessionAutocompleteField(
                        controller: sessionController,
                        labelText: 'Session 名稱',
                        hintText: 'patient_2025_1101',
                        enabled: !isLoading,
                        onSubmitted: isLoading ? null : (_) => onLoadSession(),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isLoading ? null : onBrowseSessions,
                            icon: const Icon(Icons.search),
                            label: const Text('瀏覽'),
                          ),
                          FilledButton.icon(
                            onPressed: isLoading ? null : onLoadSession,
                            icon: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.analytics_outlined),
                            label: Text(isLoading ? '載入中' : '載入頻譜'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (activeSession.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.dividerColor),
                      color: context.cardColor,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: accent.success,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '目前 Session：',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activeSession,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
