import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/minutely_cadence_bars_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/swing_info_heatmap/swing_info_heatmap_chart.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/swing_info_heatmap/swing_info_heatmap_header.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';

/// 每分鐘左右擺動期（swing）熱圖的主視圖。
class SwingInfoHeatmapView extends ConsumerStatefulWidget {
  const SwingInfoHeatmapView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  ConsumerState<SwingInfoHeatmapView> createState() =>
      _SwingInfoHeatmapViewState();
}

class _SwingInfoHeatmapViewState extends ConsumerState<SwingInfoHeatmapView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(swingInfoHeatmapProvider);
    final config = ref.watch(swingInfoHeatmapConfigProvider);
    final failure = ref.watch(requestFailureProvider('swing_info_heatmap'));
    final isLoading = dataAsync.isLoading && failure == null;

    void handleLoad() {
      // 「載入熱圖」按鈕視為 retry：清除 failure gate 並強制刷新 provider。
      ref.read(requestFailureStoreProvider.notifier).clearFailure(
            'swing_info_heatmap',
          );
      ref.read(requestFailureStoreProvider.notifier).clearFailure(
            'minutely_cadence_bars_swing',
          );
      widget.onLoadSession();
      ref.invalidate(swingInfoHeatmapProvider);
      ref.invalidate(minutelyCadenceBarsForSwingProvider);
    }

    final minutelyAsync = ref.watch(minutelyCadenceBarsForSwingProvider);
    final minutelyData = minutelyAsync.asData?.value;
    final showMinutelySection =
        minutelyAsync.isLoading ||
        minutelyAsync.hasError ||
        (minutelyData != null && !minutelyData.isEmpty);

    return ListView(
      controller: _scrollController,
      padding: dashboardPagePadding(context),
      children: [
        SwingInfoHeatmapHeader(
          sessionController: widget.sessionController,
          onLoadSession: handleLoad,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        AsyncRequestView(
          requestId: 'swing_info_heatmap',
          value: dataAsync,
          loadingLabel: '載入 Swing 熱圖…',
          isEmpty: (response) => response.isEmpty,
          emptyBuilder: (_) => const _SwingInfoHeatmapEmpty(),
          onRetry: () => ref.invalidate(swingInfoHeatmapProvider),
          dataBuilder: (context, response) => SwingInfoHeatmapChart(
            response: response,
            vminPct: config.vminPct,
            vmaxPct: config.vmaxPct,
          ),
        ),
        if (showMinutelySection) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AsyncRequestView<MinutelyCadenceStepLengthBarsResponse>(
                requestId: 'minutely_cadence_bars_swing',
                value: minutelyAsync,
                loadingLabel: '載入每分鐘步態變化…',
                onRetry: () =>
                    ref.invalidate(minutelyCadenceBarsForSwingProvider),
                dataBuilder: (context, data) =>
                    MinutelyCadenceBarsCard(data: data),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SwingInfoHeatmapEmpty extends StatelessWidget {
  const _SwingInfoHeatmapEmpty();

  @override
  Widget build(BuildContext context) {
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
            '尚無 Swing 熱圖資料',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請先載入 session，並確認後端已可回傳 swing_info_heatmap 結果。',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}


