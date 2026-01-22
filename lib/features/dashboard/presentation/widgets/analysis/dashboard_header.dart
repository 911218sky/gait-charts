import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/controls/projection_planes.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/navigation/dashboard_header_actions.dart';

/// 儀表板標頭，整合說明、Session 控制與設定切換。
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    required this.sessionController,
    required this.onLoadSession,
    required this.isLoading,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final config = ref.watch(stageDurationsConfigProvider);
    final configNotifier = ref.read(stageDurationsConfigProvider.notifier);
    final activeSession = ref.watch(activeSessionProvider);
    final isDefaultConfig =
        config.projection == 'xz' &&
        config.smoothWindow == 3 &&
        (config.minVAbs - 15).abs() < 1e-3 &&
        (config.flatFrac - 0.7).abs() < 1e-3;

    Future<void> browseSessions() async {
      final selected = await SessionPickerDialog.show(context);
      if (selected == null || selected.isEmpty || !context.mounted) {
        return;
      }
      sessionController.text = selected;
      onLoadSession();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        return Container(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          decoration: BoxDecoration(
            color: context.scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: context.dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCompact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rehabilitation Session Analyzer',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '輸入 session 名稱並載入階段耗時分析結果。調整投影與平滑設定以符合臨床需求。',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                DashboardHeaderActions(activeSession: activeSession),
              ],
            )
              else ...[
            Text(
              'Rehabilitation Session Analyzer',
              style: textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '輸入 session 名稱並載入階段耗時分析結果。調整投影與平滑設定以符合臨床需求。',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: DashboardHeaderActions(activeSession: activeSession),
            ),
              ],
              const SizedBox(height: 24),
              if (!isCompact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SessionAutocompleteField(
                    controller: sessionController,
                    labelText: 'Session 名稱',
                    hintText: '例如：patient_2025_1101',
                    onSubmitted: (_) => onLoadSession(),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : browseSessions,
                  icon: const Icon(Icons.search),
                  label: const Text('瀏覽 Sessions'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 22,
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
                      : const Icon(Icons.auto_graph),
                  label: Text(isLoading ? '載入中' : '載入分析'),
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
                  onSubmitted: (_) => onLoadSession(),
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
                          : const Icon(Icons.auto_graph),
                      label: Text(isLoading ? '載入中' : '載入分析'),
                    ),
                  ],
                ),
              ],
            ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ProjectionSelector(
                    current: config.projection,
                    onChanged: configNotifier.updateProjection,
                  ),
                  AppIntSliderTile(
                    label: '平滑視窗',
                    value: config.smoothWindow,
                    min: 1,
                    max: 15,
                    onChanged: configNotifier.updateSmoothWindow,
                    tooltip: '移動平均視窗大小，用於平滑原始軌跡數據',
                  ),
                  AppDoubleSliderTile(
                    label: 'min_v_abs',
                    value: config.minVAbs,
                    min: 5,
                    max: 40,
                    step: 0.5,
                    suffix: 'm/s',
                    onChanged: configNotifier.updateMinVAbs,
                    tooltip: '速度閾值：低於此速度會被視為靜止段',
                  ),
                  AppDoubleSliderTile(
                    label: 'flat_frac',
                    value: config.flatFrac,
                    min: 0.3,
                    max: 1,
                    step: 0.05,
                    onChanged: configNotifier.updateFlatFrac,
                    tooltip: '平坦比例：用於判斷平坦區段的比例閾值',
                  ),
                  TextButton.icon(
                    onPressed: isDefaultConfig ? null : configNotifier.reset,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重置設定'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 投影平面選擇器。
class _ProjectionSelector extends StatelessWidget {
  const _ProjectionSelector({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  static const _options = projectionPlaneOptions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '投影平面',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 180,
          child: AppSelect<String>(
            value: current,
            items: _options,
            onChanged: onChanged,
            itemLabelBuilder: (item) => item.toUpperCase(),
            menuWidth: const BoxConstraints(minWidth: 120, maxWidth: 200),
          ),
        ),
      ],
    );
  }
}
