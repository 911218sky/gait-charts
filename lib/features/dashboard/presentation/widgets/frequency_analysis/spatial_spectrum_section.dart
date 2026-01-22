import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

import 'frequency_analysis_widgets.dart';

/// 空間頻譜區塊，分析 XZ/YZ 平面軌跡的頻率特徵
class SpatialSpectrumSection extends ConsumerWidget {
  const SpatialSpectrumSection({required this.data, super.key});

  final AsyncValue<SpatialSpectrumResponse> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(spatialSpectrumConfigProvider);
    final notifier = ref.read(spatialSpectrumConfigProvider.notifier);
    final chartConfig = ref.watch(chartConfigProvider);
    final accent = DashboardAccentColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FrequencySectionHeader(
              title: 'Spatial Spectrum 空間頻譜',
              subtitle: '比較 X(Z) / Y(Z) 曲線的能量峰值，評估軌跡穩定度。',
              accent: accent,
            ),
            const SizedBox(height: 16),
            SpatialSpectrumControls(config: config, notifier: notifier),
            const SizedBox(height: 16),
            AsyncRequestView<SpatialSpectrumResponse>(
              requestId: 'spatial_spectrum',
              value: data,
              loadingLabel: '運算空間頻譜中…',
              onRetry: () => ref.invalidate(spatialSpectrumProvider),
              dataBuilder: (context, response) {
                if (response.isEmpty) {
                  return const FrequencyEmptyState(
                    message: '尚未取得空間頻譜，請確認 Session 已載入並重新分析。',
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
                      maxSamples: chartConfig.spatialSpectrumMaxPoints,
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

/// 空間頻譜的參數控制面板 (平面選擇、平滑係數、峰值設定)
class SpatialSpectrumControls extends StatelessWidget {
  const SpatialSpectrumControls({
    required this.config,
    required this.notifier,
    super.key,
  });

  final SpatialSpectrumConfig config;
  final SpatialSpectrumConfigNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            buildFrequencyToggleChip(
              context,
              label: 'XZ',
              selected: config.pairs.contains('xz'),
              accentColor: DashboardAccentColors.of(context).success,
              onTap: () => notifier.togglePair('xz'),
              tooltip: 'XZ 平面：水平面（左右 + 前後）',
            ),
            buildFrequencyToggleChip(
              context,
              label: 'YZ',
              selected: config.pairs.contains('yz'),
              accentColor: DashboardAccentColors.of(context).success,
              onTap: () => notifier.togglePair('yz'),
              tooltip: 'YZ 平面：矢狀面（垂直 + 前後）',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            AppIntSliderTile(
              label: 'k-smooth',
              value: config.kSmooth,
              min: 1,
              max: 10,
              onChanged: notifier.updateKSmooth,
              tooltip: '頻譜平滑係數，降低雜訊影響',
            ),
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
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: notifier.reset,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重置參數'),
          ),
        ),
      ],
    );
  }
}
