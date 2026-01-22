import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/controls/heatmap_color_range_selector.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/controls/projection_planes.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/navigation/dashboard_header_actions.dart';

/// speed_heatmap 的 Header，包含 session 輸入與查詢設定。
class SpeedHeatmapHeader extends ConsumerWidget {
  const SpeedHeatmapHeader({
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
    final activeSession = ref.watch(activeSessionProvider);
    final config = ref.watch(speedHeatmapConfigProvider);
    final notifier = ref.read(speedHeatmapConfigProvider.notifier);
    final colorRange = ref.watch(speedHeatmapColorRangeProvider);
    final colorRangeNotifier = ref.read(speedHeatmapColorRangeProvider.notifier);

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

        final settings = Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ProjectionSelector(
              current: config.projection,
              onChanged: notifier.updateProjection,
            ),
            AppIntSliderTile(
              label: '平滑視窗 (s)',
              value: config.smoothWindow,
              min: 1,
              max: 15,
              onChanged: notifier.updateSmoothWindow,
              tooltip: '速度序列平滑視窗，越大越平順但細節較少',
            ),
            AppDoubleSliderTile(
              label: 'min_v_abs',
              value: config.minVAbs,
              min: 5,
              max: 40,
              step: 1,
              width: 340,
              suffix: 'm/s',
              onChanged: notifier.updateMinVAbs,
              tooltip: '步態檢測的速度閾值，過低會增加雜訊',
            ),
            AppDoubleSliderTile(
              label: 'flat_frac',
              value: config.flatFrac,
              min: 0.3,
              max: 1,
              step: 0.05,
              onChanged: notifier.updateFlatFrac,
              tooltip: '平坦度比例，用於判定轉彎區段的門檻',
            ),
            AppIntSliderTile(
              label: '重採樣寬度',
              value: config.width,
              min: 50,
              max: 500,
              onChanged: notifier.updateWidth,
              tooltip: '每圈要重採樣成多少點，影響 x 軸解析度',
              helperText: '增加寬度可看細節，但繪圖成本也會增加',
            ),
            HeatmapColorRangeSelector(
              vmin: colorRange.vmin,
              vmax: colorRange.vmax,
              onChangedMin: colorRangeNotifier.updateVmin,
              onChangedMax: colorRangeNotifier.updateVmax,
              onAuto: colorRangeNotifier.useAutoRange,
              label: '顏色區間 (m/s)',
              defaultMin: 0.0,
              defaultMax: 2.0,
            ),
            TextButton.icon(
              onPressed: notifier.reset,
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重置設定'),
            ),
          ],
        );

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
                            'Speed Heatmap',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '檢視每圈的速度分佈與錐桶轉身區段，調整平滑與色階參數以凸顯異常。',
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
                  'Speed Heatmap',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '檢視每圈的速度分佈與錐桶轉身區段，調整平滑與色階參數以凸顯異常。',
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
              const SizedBox(height: 20),
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
                          : const Icon(Icons.speed),
                      label: Text(isLoading ? '載入中' : '載入熱圖'),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.speed),
                          label: Text(isLoading ? '載入中' : '載入熱圖'),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              if (!isCompact)
                settings
              else
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 12),
                  title: Text(
                    '查詢設定',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '投影 / 平滑 / 色階 / 重採樣',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  children: [settings],
                ),
            ],
          ),
        );
      },
    );
  }
}

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
          width: 170,
          child: AppSelect<String>(
            value: current,
            items: _options,
            onChanged: onChanged,
            itemLabelBuilder: (val) => val.toUpperCase(),
            menuWidth: const BoxConstraints(minWidth: 120, maxWidth: 200),
          ),
        ),
      ],
    );
  }
}
