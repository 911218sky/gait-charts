import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/dashboard_header.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/device_status_section.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/joint_selector.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/metric_cards_grid.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/session_overview_chart.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/stage_duration/stage_average_radar_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/stage_duration/stage_duration_chart.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';

/// 展示步態分期分析資料的主要畫面。
class DashboardAnalysisView extends ConsumerStatefulWidget {
  const DashboardAnalysisView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  ConsumerState<DashboardAnalysisView> createState() =>
      _DashboardAnalysisViewState();
}

class _DashboardAnalysisViewState extends ConsumerState<DashboardAnalysisView> {
  late final ScrollController _scrollController;
  final GlobalKey _detailSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToDetails() {
    final targetContext = _detailSectionKey.currentContext;
    if (targetContext == null) {
      return;
    }
    // 滑動到圈數細節區，方便從總覽快速聚焦
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stageDurationsAsync = ref.watch(stageDurationsProvider);
    final analytics = ref.watch(stageDurationsAnalyticsProvider);
    final stageFailure = ref.watch(requestFailureProvider('stage_durations'));

    void handleLoad() {
      // 使用者再次點擊「載入分析」時，視為明確的 retry：
      // 先清除 failure gate，避免停留在相同 fingerprint 的快取錯誤。
      ref.read(requestFailureStoreProvider.notifier).clearFailure(
            'stage_durations',
          );
      widget.onLoadSession();
    }

    final dataSection = AsyncRequestView<StageDurationsResponse>(
      requestId: 'stage_durations',
      value: stageDurationsAsync,
      loadingLabel: '讀取分析資料中…',
      onRetry: () => ref.invalidate(stageDurationsProvider),
      dataBuilder: (context, response) => StageAnalyticsContent(
        response: response,
        analytics: analytics,
        detailSectionKey: _detailSectionKey,
        onLapFocusRequest: _scrollToDetails,
      ),
    );

    return ListView(
      controller: _scrollController,
      padding: dashboardPagePadding(context),
      children: [
        DashboardHeader(
          sessionController: widget.sessionController,
          onLoadSession: handleLoad,
          // 若 request 已經失敗（failure store 有紀錄），header 不應該繼續顯示「載入中」。
          // 這能避免 error 卡片已經顯示，但右上角仍一直轉圈的 UX。
          isLoading: stageDurationsAsync.isLoading && stageFailure == null,
        ),
        const SizedBox(height: 24),
        dataSection,
      ],
    );
  }
}

/// 根據回應資料繪製卡片、圖表與圈數詳情。
class StageAnalyticsContent extends ConsumerWidget {
  const StageAnalyticsContent({
    required this.response,
    required this.analytics,
    required this.detailSectionKey,
    required this.onLapFocusRequest,
    super.key,
  });

  final StageDurationsResponse response;
  final StageDurationsAnalytics? analytics;
  final GlobalKey detailSectionKey;
  final VoidCallback onLapFocusRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (response.laps.isEmpty) {
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
              '尚未有分析結果',
              style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '請確認 session 已透過 Extract API 建立，或重新執行提取流程。',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final isWide = context.isAnalysisWide;
    final accent = DashboardAccentColors.of(context);
    final selectedLapIndex = ref.watch(selectedLapIndexProvider);
    final selectedLap = response.laps.firstWhere(
      (lap) => lap.lapIndex == selectedLapIndex,
      orElse: () => response.laps.first,
    );

    final chart = Expanded(
      flex: 3,
      child: StageDurationChart(selectedLap: selectedLap),
    );
    final details = Expanded(
      flex: 2,
      child: StageDetailsSection(lap: selectedLap),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 總覽各圈表現的迷你圖，支援點擊聚焦圈數
        SessionOverviewChart(
          laps: response.laps,
          onLapFocusRequested: onLapFocusRequest,
        ),
        const SizedBox(height: 24),
        // 核心統計卡片 (平均/極值等快速摘要)
        MetricCardsGrid(analytics: analytics, accent: accent),
        const SizedBox(height: 24),
        if ((analytics?.stageAverageDurations ?? {}).isNotEmpty) ...[
          // 分期平均時長的雷達圖，視資料存在與否決定顯示
          StageAverageRadarCard(analytics: analytics),
          const SizedBox(height: 24),
        ],
        // 圈數選擇器：切換下方詳圖的目標圈
        StageLapSelector(laps: response.laps),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: detailSectionKey,
          child: isWide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [chart, const SizedBox(width: 24), details],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StageDurationChart(selectedLap: selectedLap),
                    const SizedBox(height: 24),
                    StageDetailsSection(lap: selectedLap),
                  ],
                ),
        ),
      ],
    );
  }
}
