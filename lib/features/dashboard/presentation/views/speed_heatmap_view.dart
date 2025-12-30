import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/speed_heatmap/speed_heatmap_chart.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/speed_heatmap/speed_heatmap_header.dart';

/// 每圈速度熱圖的主視圖。
class SpeedHeatmapView extends ConsumerStatefulWidget {
  const SpeedHeatmapView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  ConsumerState<SpeedHeatmapView> createState() => _SpeedHeatmapViewState();
}

class _SpeedHeatmapViewState extends ConsumerState<SpeedHeatmapView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(speedHeatmapProvider);
    final vmin = ref.watch(speedHeatmapColorRangeProvider.select((c) => c.vmin));
    final vmax = ref.watch(speedHeatmapColorRangeProvider.select((c) => c.vmax));
    final failure = ref.watch(requestFailureProvider('speed_heatmap'));
    final isLoading = dataAsync.isLoading && failure == null;

    void handleLoad() {
      // 「載入熱圖」按鈕視為 retry：清除 failure gate 並強制刷新 provider。
      ref.read(requestFailureStoreProvider.notifier).clearFailure(
            'speed_heatmap',
          );
      widget.onLoadSession();
      ref.invalidate(speedHeatmapProvider);
    }

    return ListView(
      controller: _scrollController,
      padding: dashboardPagePadding(context),
      children: [
        SpeedHeatmapHeader(
          sessionController: widget.sessionController,
          onLoadSession: handleLoad,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        AsyncRequestView(
          requestId: 'speed_heatmap',
          value: dataAsync,
          loadingLabel: '載入速度熱圖…',
          isEmpty: (response) => response.isEmpty,
          emptyBuilder: (_) => const _SpeedHeatmapEmpty(),
          onRetry: () => ref.invalidate(speedHeatmapProvider),
          dataBuilder: (context, response) => SpeedHeatmapChart(
            response: response,
            vmin: vmin,
            vmax: vmax,
          ),
        ),
      ],
    );
  }
}

class _SpeedHeatmapEmpty extends StatelessWidget {
  const _SpeedHeatmapEmpty();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: context.cardColor,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '尚無速度熱圖資料',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請先載入 session 並確認後端已產生 speed_heatmap 結果。',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
