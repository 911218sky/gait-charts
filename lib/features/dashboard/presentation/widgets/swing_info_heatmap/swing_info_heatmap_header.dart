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

/// swing_info_heatmap 的 Header，包含 session 輸入與查詢設定。
class SwingInfoHeatmapHeader extends ConsumerWidget {
  const SwingInfoHeatmapHeader({
    required this.sessionController,
    required this.onLoadSession,
    required this.isLoading,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;
  final bool isLoading;

  static const List<int?> _maxMinutesOptions = <int?>[
    null,
    1,
    2,
    3,
    4,
    5,
    6,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final config = ref.watch(swingInfoHeatmapConfigProvider);
    final notifier = ref.read(swingInfoHeatmapConfigProvider.notifier);
    final textTheme = context.textTheme;
    final colors = context.colorScheme;

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
            AppDoubleSliderTile(
              label: '平滑視窗 (s)',
              value: config.smoothWindowS,
              min: 0.5,
              max: 20,
              step: 0.5,
              width: 340,
              onChanged: notifier.updateSmoothWindowS,
              tooltip: '統計前的平滑窗口，越大越平順但細節較少',
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
              tooltip: '平坦度比例，用於判定某些區段門檻',
            ),
            _MaxMinutesSelector(
              current: config.maxMinutes,
              onChanged: notifier.updateMaxMinutes,
            ),
            HeatmapColorRangeSelector(
              vmin: config.vminPct,
              vmax: config.vmaxPct,
              onChangedMin: notifier.updateVminPct,
              onChangedMax: notifier.updateVmaxPct,
              onAuto: notifier.useAutoColorRange,
              label: '顏色區間 (Swing%)',
              defaultMin: 30.0,
              defaultMax: 45.0,
            ),
            TextButton.icon(
              onPressed: notifier.reset,
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
                            'Swing Heatmap',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '每分鐘區間的 Left/Right swing% 與 swing 秒數，供前端渲染熱力圖與觀察對稱性變化。',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.7),
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
                  'Swing Heatmap',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '每分鐘區間的 Left/Right swing% 與 swing 秒數，供前端渲染熱力圖與觀察對稱性變化。',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
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
                          : const Icon(Icons.grid_view_outlined),
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
                              : const Icon(Icons.grid_view_outlined),
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
                    '投影 / 平滑 / 色階 / 分段',
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
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '投影平面',
          style: textTheme.labelSmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
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

class _MaxMinutesSelector extends StatelessWidget {
  const _MaxMinutesSelector({required this.current, required this.onChanged});

  final int? current;
  final ValueChanged<int?> onChanged;

  static const _options = SwingInfoHeatmapHeader._maxMinutesOptions;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '最多分鐘數',
          style: textTheme.labelSmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 170,
          child: AppSelect<int?>(
            value: current,
            items: _options,
            onChanged: onChanged,
            itemLabelBuilder: (val) => val == null ? 'Auto' : '$val min',
            menuWidth: const BoxConstraints(minWidth: 140, maxWidth: 220),
            tooltip: '限制最多顯示的分鐘數，避免過長 session 畫面太擠',
          ),
        ),
      ],
    );
  }
}

