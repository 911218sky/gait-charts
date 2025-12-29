import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';

/// 提供使用者調整圖表取樣點數的設定面板。
class ChartConfigPanel extends ConsumerWidget {
  const ChartConfigPanel({super.key});

  static const _options = <int>[60, 120, 250, 500, 900, 1500, 2500];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final config = ref.watch(chartConfigProvider);
    final controller = ref.read(chartConfigProvider.notifier);

    // 定義選項列表，方便用 Grid/Wrap 生成
    final items = [
      _ConfigItem(
        label: 'Y-Height Diff',
        value: config.yHeightDiffMaxPoints,
        onChanged: controller.updateYHeightDiff,
        tooltip: 'Y 軸高度差圖表的取樣點數',
      ),
      _ConfigItem(
        label: 'Per-lap Series',
        value: config.perLapSeriesMaxPoints,
        onChanged: controller.updatePerLapSeries,
        tooltip: '每圈序列圖表的取樣點數',
      ),
      _ConfigItem(
        label: 'Per-lap PSD',
        value: config.perLapPsdMaxPoints,
        onChanged: controller.updatePerLapPsd,
        tooltip: '每圈 PSD (功率譜密度) 圖表的取樣點數',
      ),
      _ConfigItem(
        label: 'Per-lap θ(t)',
        value: config.perLapThetaMaxPoints,
        onChanged: controller.updatePerLapTheta,
        tooltip: '每圈角度變化圖表的取樣點數',
      ),
      _ConfigItem(
        label: 'Panorama',
        value: config.perLapOverviewMaxPoints,
        onChanged: controller.updatePerLapOverview,
        tooltip: '全景圖表的取樣點數',
      ),
      _ConfigItem(
        label: 'Spatial Spectrum',
        value: config.spatialSpectrumMaxPoints,
        onChanged: controller.updateSpatialSpectrum,
        tooltip: '空間頻譜圖表的取樣點數',
      ),
      _ConfigItem(
        label: 'Multi-FFT',
        value: config.multiFftMaxPoints,
        onChanged: controller.updateMultiFft,
        tooltip: '多關節頻譜圖表的取樣點數',
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 380;
          final padding = EdgeInsets.all(isCompact ? 16 : 24);

          final header = isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.tune, size: 20, color: colors.onSurface),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Chart Rendering Preferences',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppTooltip(
                          message: '關閉設定',
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                            onPressed: () => context.navigator.pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '調整各圖表的最大取樣點數（效能 vs 細節）',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.tune, size: 20, color: colors.onSurface),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chart Rendering Preferences',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppTooltip(
                      message: '關閉設定',
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        onPressed: () => context.navigator.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                );

          final content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 24),

                // Grid Layout for Settings
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 手機：1 欄；一般：2 欄；寬版：3 欄
                    final crossAxisCount = constraints.maxWidth < 420
                        ? 1
                        : (constraints.maxWidth > 560 ? 3 : 2);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 75, // 固定高度，避免窄寬度被切掉
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 20,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _ConfigDropdown(
                          label: item.label,
                          value: item.value,
                          options: _options,
                          onChanged: item.onChanged,
                          tooltip: item.tooltip,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Footer (Reset + Description)
                if (!isCompact)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '降採樣點數可提升繪圖效能，增大點數則能保留更多細節。',
                          style: TextStyle(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: controller.reset,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('重置預設'),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '降採樣點數可提升繪圖效能，增大點數則能保留更多細節。',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: controller.reset,
                            style: TextButton.styleFrom(
                              foregroundColor: colors.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('重置預設'),
                          ),
                        ],
                      ),
                    ],
                  ),
            ],
          );

          // 手機/小視窗高度不足時避免 Column overflow：讓內容可捲動
          final body = constraints.maxHeight.isFinite
              ? SingleChildScrollView(child: content)
              : content;

          return Padding(
            padding: padding,
            child: body,
          );
        },
      ),
    );
  }
}

class _ConfigItem {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String tooltip;

  _ConfigItem({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.tooltip,
  });
}

class _ConfigDropdown extends StatelessWidget {
  const _ConfigDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.tooltip,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTooltip(
          message: tooltip,
          textStyle: TextStyle(
            color: isDark ? const Color(0xFFE0E0E0) : colors.onInverseSurface,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          verticalOffset: 12,
          preferBelow: false,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : colors.inverseSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 14,
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 150,
          child: AppSelect<int>(
            value: value,
            items: options,
            onChanged: onChanged,
            menuWidth: const BoxConstraints(minWidth: 120, maxWidth: 200),
          ),
        ),
      ],
    );
  }
}
