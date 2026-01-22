import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/chart/y_height_diff.dart';

// Re-export HeightUnit for backward compatibility
export 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/chart/height_unit.dart';

/// 包裝高度差趨勢圖的卡片。
class YHeightDiffChartSection extends ConsumerStatefulWidget {
  const YHeightDiffChartSection({
    required this.response,
    required this.unit,
    required this.onUnitChanged,
    super.key,
  });

  final YHeightDiffResponse response;
  final HeightUnit unit;
  final ValueChanged<HeightUnit> onUnitChanged;

  @override
  ConsumerState<YHeightDiffChartSection> createState() =>
      _YHeightDiffChartSectionState();
}

class _YHeightDiffChartSectionState
    extends ConsumerState<YHeightDiffChartSection> {
  bool _showSamples = false;
  int? _sampleLimit = 120;
  RangeValues? _viewRange;
  bool _showDiff = true;

  @override
  Widget build(BuildContext context) {
    final accent = DashboardAccentColors.of(context);
    final response = widget.response;
    final chartConfig = ref.watch(chartConfigProvider);
    final maxPoints = chartConfig.yHeightDiffMaxPoints;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildChartContent(
          chartHeight: 320,
          accent: accent,
          response: response,
          maxPoints: maxPoints,
        ),
      ),
    );
  }

  Widget _buildChartContent({
    required double chartHeight,
    DashboardAccentColors? accent,
    YHeightDiffResponse? response,
    int? maxPoints,
  }) {
    final effectiveResponse = response ?? widget.response;
    final effectiveAccent = accent ?? DashboardAccentColors.of(context);
    final effectiveMaxPoints = effectiveResponse.timeSeconds.length;
    final strokeThreshold = ref.read(chartConfigProvider).yHeightDiffMaxPoints;
    final totalDuration = effectiveResponse.timeSeconds.isNotEmpty
        ? effectiveResponse.timeSeconds.last
        : 0.0;
    final fullRange = RangeValues(0, totalDuration > 0 ? totalDuration : 1);
    final viewRange = _clampRange(_viewRange, fullRange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(effectiveResponse),
        const SizedBox(height: 12),
        if (totalDuration > 0) _buildRangeControls(viewRange),
        _buildOptionsRow(),
        const SizedBox(height: 12),
        YHeightDiffInternalChart(
          response: effectiveResponse,
          accent: effectiveAccent,
          unit: widget.unit,
          showSamples: _showSamples,
          sampleLimit: _sampleLimit,
          maxPoints: effectiveMaxPoints,
          viewRange: viewRange,
          showDiff: _showDiff,
          strokeThreshold: strokeThreshold,
          onRangeSelected: (range) => setState(() => _viewRange = range),
          onResetView: () => setState(() => _viewRange = null),
          chartHeight: chartHeight,
        ),
      ],
    );
  }

  Widget _buildHeader(YHeightDiffResponse response) {
    final colors = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '高度差趨勢',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '三條曲線同步呈現：左、右高度與差值，預設已平移到 0 起點。',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Chip(
          label: Text(
            'Joints ${response.leftJoint} / ${response.rightJoint}',
          ),
        ),
      ],
    );
  }

  Widget _buildRangeControls(RangeValues viewRange) {
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _viewRange = null),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重置區間'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '區間：${viewRange.start.toStringAsFixed(1)} – ${viewRange.end.toStringAsFixed(1)} s',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '提示：在圖上拖曳可放大，雙擊圖表重置',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow() {
    final colors = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '顯示 Diff',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: _showDiff,
          onChanged: (value) => setState(() => _showDiff = value),
        ),
        const SizedBox(width: 24),
        Text(
          '單位',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<HeightUnit>(
          segments: const [
            ButtonSegment(value: HeightUnit.cm, label: Text('cm'), tooltip: '以公分 (cm) 顯示高度'),
            ButtonSegment(value: HeightUnit.m, label: Text('m'), tooltip: '以公尺 (m) 顯示高度'),
          ],
          selected: {widget.unit},
          showSelectedIcon: false,
          onSelectionChanged: (values) => widget.onUnitChanged(values.first),
        ),
        const SizedBox(width: 24),
        Text(
          '顯示取樣點',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: _showSamples,
          onChanged: (value) => setState(() => _showSamples = value),
        ),
        const SizedBox(width: 24),
        Text(
          '最多點數',
          style: context.textTheme.bodySmall?.copyWith(
            color: _showSamples ? colors.onSurface : colors.onSurface.withValues(alpha: 0.3),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: AppSelect<int?>(
            value: _sampleLimit,
            items: const [60, 120, 240, null],
            itemLabelBuilder: (item) => item?.toString() ?? '不限制',
            enabled: _showSamples,
            onChanged: _showSamples ? (value) => setState(() => _sampleLimit = value) : null,
            menuWidth: const BoxConstraints(minWidth: 100, maxWidth: 140),
          ),
        ),
      ],
    );
  }

  RangeValues _clampRange(RangeValues? value, RangeValues full) {
    if (value == null) return full;
    var start = value.start.clamp(full.start, full.end);
    var end = value.end.clamp(full.start, full.end);
    if (end - start < 1e-3) return full;
    if (start > end) {
      final temp = start;
      start = end;
      end = temp;
    }
    return RangeValues(start, end);
  }
}
