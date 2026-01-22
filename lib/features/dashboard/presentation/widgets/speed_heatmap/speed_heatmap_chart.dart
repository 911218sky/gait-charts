import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'widgets/widgets.dart';

/// 呈現速度熱圖與色階說明。
class SpeedHeatmapChart extends StatelessWidget {
  const SpeedHeatmapChart({
    required this.response,
    this.vmin,
    this.vmax,
    super.key,
  });

  final SpeedHeatmapResponse response;
  final double? vmin;
  final double? vmax;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final heatmapPalette = DashboardHeatmapPalette.of(context);
    final textTheme = context.textTheme;

    // UI 若有手動指定色階，優先使用；否則依資料 min/max
    final colorMin = vmin ?? response.dataMin;
    final colorMax = vmax ?? response.dataMax;
    final scale = HeatmapColorScale(
      min: colorMin,
      max: colorMax,
      palette: heatmapPalette,
    );

    final chartHeight = math.max(180.0, response.lapCount * 28.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, textTheme, colors, scale),
            const SizedBox(height: 12),
            SummaryChips(
              width: response.width,
              laps: response.lapCount,
              vmin: colorMin,
              vmax: colorMax,
            ),
            const SizedBox(height: 16),
            SpeedHeatmapBoard(
              response: response,
              scale: scale,
              height: chartHeight,
            ),
            const SizedBox(height: 8),
            Text(
              '灰線為圈與進度切分，帶有斜線與標籤的區塊代表轉身位置，色階越亮表示速度越高。',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colors,
    HeatmapColorScale scale,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(textTheme, colors),
              const SizedBox(height: 6),
              _buildSubtitle(textTheme, colors),
              const SizedBox(height: 12),
              HeatmapLegend(
                scale: scale,
                dataMin: response.dataMin,
                dataMax: response.dataMax,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(textTheme, colors),
                  const SizedBox(height: 6),
                  _buildSubtitle(textTheme, colors),
                ],
              ),
            ),
            const SizedBox(width: 16),
            HeatmapLegend(
              scale: scale,
              dataMin: response.dataMin,
              dataMax: response.dataMax,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle(TextTheme textTheme, ColorScheme colors) {
    return Text(
      '每圈速度時空熱圖',
      style: textTheme.titleLarge?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubtitle(TextTheme textTheme, ColorScheme colors) {
    return Text(
      '以固定寬度重採樣每圈速度，並標示轉身區段。',
      style: textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
