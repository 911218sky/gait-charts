import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/navigation/dashboard_header_actions.dart';

/// Trajectory 簡易版 Header：只留 Session 載入。
/// 詳細參數設定改放到 body 右側面板。
class TrajectorySimpleHeader extends ConsumerWidget {
  const TrajectorySimpleHeader({
    required this.sessionController,
    required this.onLoadSession,
    required this.isLoading,
    this.onOpenConfig,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;
  final bool isLoading;
  final VoidCallback? onOpenConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final isCompact = context.isCompactHeader;

    Future<void> browseSessions() async {
      final selected = await SessionPickerDialog.show(context);
      if (selected == null || selected.isEmpty || !context.mounted) {
        return;
      }
      sessionController.text = selected;
      onLoadSession();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24, vertical: 16),
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Column(
        children: [
          // 第一列：標題 + Theme/Session Actions
          if (!isCompact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Trajectory Playback',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '以點位重建 top-down 軌跡',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (onOpenConfig != null) ...[
                  IconButton(
                    tooltip: '播放設定',
                    onPressed: onOpenConfig,
                    icon: const Icon(Icons.tune),
                  ),
                  const SizedBox(width: 4),
                ],
                DashboardHeaderActions(activeSession: activeSession),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Trajectory Playback',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '以點位重建 top-down 軌跡',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onOpenConfig != null) ...[
                      OutlinedButton.icon(
                        onPressed: onOpenConfig,
                        icon: const Icon(Icons.tune),
                        label: const Text('播放設定'),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    DashboardHeaderActions(activeSession: activeSession),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),
          // 第二列：Session Input + Search + Load Button
          if (!isCompact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SessionAutocompleteField(
                    controller: sessionController,
                    labelText: 'Session 名稱',
                    hintText: '例如：patient_2025_1101',
                    enabled: !isLoading,
                    onSubmitted: isLoading ? null : (_) => onLoadSession(),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : browseSessions,
                  icon: const Icon(Icons.search),
                  label: const Text('瀏覽'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20, // Make it tall enough to match input
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: isLoading ? null : onLoadSession,
                  icon: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_outline),
                  label: Text(isLoading ? '載入中' : '載入軌跡'),
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
                  hintText: '例如：patient_2025_1101',
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
                      onPressed: isLoading ? null : browseSessions,
                      icon: const Icon(Icons.search),
                      label: const Text('瀏覽'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: isLoading ? null : onLoadSession,
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_circle_outline),
                      label: Text(isLoading ? '載入中' : '載入軌跡'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

