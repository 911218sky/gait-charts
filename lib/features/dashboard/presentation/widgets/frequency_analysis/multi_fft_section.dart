import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/controls/fft_periodogram_settings.dart';

import 'frequency_analysis_widgets.dart';

/// 多關節 FFT 頻譜區塊，展示各關節時間序列的功率頻譜密度
class MultiFftSection extends ConsumerWidget {
  const MultiFftSection({required this.data, super.key});

  final AsyncValue<MultiFftSeriesResponse> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(multiFftConfigProvider);
    final notifier = ref.read(multiFftConfigProvider.notifier);
    final chartConfig = ref.watch(chartConfigProvider);
    final accent = DashboardAccentColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FrequencySectionHeader(
              title: 'Multi-FFT 多關節頻譜',
              subtitle: '比較多組關節序列的 FFT / PSD，協助辨識震盪頻帶。',
              accent: accent,
            ),
            const SizedBox(height: 16),
            MultiFftControls(config: config, notifier: notifier),
            const SizedBox(height: 16),
            AsyncRequestView<MultiFftSeriesResponse>(
              requestId: 'multi_fft_from_series',
              value: data,
              loadingLabel: '運算關節頻譜中…',
              onRetry: () => ref.invalidate(multiFftSeriesProvider),
              dataBuilder: (context, response) {
                if (response.isEmpty) {
                  return const FrequencyEmptyState(
                    message: '尚未取得多關節頻譜，請確認已選擇至少一組 Preset。',
                  );
                }
                final palette = frequencySeriesPalette();
                final series = <FrequencySeries>[];
                for (var i = 0; i < response.series.length; i++) {
                  final entry = response.series[i];
                  if (!entry.hasData) {
                    continue;
                  }
                  final color = palette[i % palette.length];
                  series.add(
                    FrequencySeries(
                      label: entry.label,
                      xValues: entry.frequencyHz,
                      yValues: entry.psdDb,
                      color: color,
                      peaks: entry.peaks
                          .map(
                            (peak) =>
                                FrequencyPeak(freq: peak.freqHz, db: peak.db),
                          )
                          .toList(),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FrequencyLineChart(
                      series: series,
                      xLabel: '頻率 (Hz)',
                      yLabel: '相對功率 (dB)',
                      emptyLabel: '頻譜資料不足',
                      maxSamples: chartConfig.multiFftMaxPoints,
                    ),
                    const SizedBox(height: 16),
                    PeakSummaryList(
                      entries: series
                          .map(
                            (entry) => PeakSummaryEntry(
                              label: entry.label,
                              color: entry.color,
                              peaks: entry.peaks,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 多關節 FFT 的參數控制面板 (軸向、峰值設定、關節選取)
class MultiFftControls extends StatelessWidget {
  const MultiFftControls({
    required this.config,
    required this.notifier,
    super.key,
  });

  final MultiFftFromSeriesConfig config;
  final MultiFftConfigNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final selectedIds = config.joints.map((entry) => entry.id).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Component',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in const [
                  ('x', 'X', 'X 軸：左右方向 (Lateral)'),
                  ('y', 'Y', 'Y 軸：垂直方向 (Vertical)'),
                  ('z', 'Z', 'Z 軸：前後方向 (Anterior-Posterior)'),
                ])
                  _ComponentPill(
                    value: entry.$1,
                    label: entry.$2,
                    tooltip: entry.$3,
                    selected: config.component == entry.$1,
                    onSelected: () => notifier.updateComponent(entry.$1),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            AppIntSliderTile(
              label: 'Top K',
              value: config.topK ?? 0,
              min: 0,
              max: 6,
              onChanged: (value) =>
                  notifier.updateTopK(value == 0 ? null : value),
              helperText: '0 表示不限制',
              tooltip: '每條曲線最多標註的峰值數量',
            ),
            AppDoubleSliderTile(
              label: '最低 dB',
              value: config.minDb,
              min: -80,
              max: -5,
              step: 1,
              width: 340,
              onChanged: notifier.updateMinDb,
              formatter: (value) => '${value.toStringAsFixed(0)} dB',
              tooltip: '峰值判定的最低振幅閾值',
            ),
            AppDoubleSliderTile(
              label: '最低頻率',
              value: config.minFreq,
              min: 0,
              max: 3,
              step: 0.05,
              width: 340,
              onChanged: notifier.updateMinFreq,
              formatter: (value) => '${value.toStringAsFixed(2)} Hz',
              tooltip: '分析的最低頻率起點',
            ),
            AppDoubleSliderTile(
              label: '峰距比例',
              value: config.minPeakDistanceRatio,
              min: 0.005,
              max: 0.2,
              step: 0.01,
              onChanged: notifier.updateMinPeakDistance,
              formatter: (value) => value.toStringAsFixed(3),
              tooltip: '相鄰峰值的最小間距比例',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Preset 關節群組',
          style: context.textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kMultiFftJointPresets
              .map(
                (preset) => buildFrequencyToggleChip(
                  context,
                  label: preset.label,
                  selected: selectedIds.contains(preset.id),
                  accentColor: DashboardAccentColors.of(context).warning,
                  onTap: () => notifier.togglePreset(preset.id),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: notifier.reset,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重置 Preset'),
          ),
        ),
        const SizedBox(height: 16),
        FftPeriodogramSettings(
          params: config.fftParams,
          onChanged: notifier.updateFftParams,
        ),
      ],
    );
  }
}

class _ComponentPill extends StatelessWidget {
  const _ComponentPill({
    required this.value,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onSelected,
  });

  final String value;
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    final bgColor = selected
        ? accent.success.withValues(alpha: 0.12)
        : context.surfaceDark;
    final borderColor = selected
        ? accent.success
        : (context.isDark ? const Color(0xFF444444) : colors.outlineVariant);
    final fgColor = selected
        ? colors.onSurface
        : colors.onSurfaceVariant;

    return AppTooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: OutlinedButton(
        onPressed: onSelected,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: context.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
