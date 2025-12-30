import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/y_height_diff_chart.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/y_height_diff_header.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/y_height_diff_metrics.dart';

/// 左右關節高度差的專屬頁面。
class YHeightDiffView extends ConsumerStatefulWidget {
  const YHeightDiffView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  ConsumerState<YHeightDiffView> createState() => _YHeightDiffViewState();
}

class _YHeightDiffViewState extends ConsumerState<YHeightDiffView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(yHeightDiffProvider);
    final failure = ref.watch(requestFailureProvider('y_height_diff'));
    final isLoading = dataAsync.isLoading && failure == null;

    void handleLoad() {
      // 「載入高度差」按鈕視為 retry：清除 failure gate 並強制刷新 provider。
      ref.read(requestFailureStoreProvider.notifier).clearFailure(
            'y_height_diff',
          );
      widget.onLoadSession();
      ref.invalidate(yHeightDiffProvider);
    }

    return ListView(
      controller: _scrollController,
      padding: dashboardPagePadding(context),
      children: [
        YHeightDiffHeader(
          sessionController: widget.sessionController,
          onLoadSession: handleLoad,
          isLoading: isLoading,
        ),
        const SizedBox(height: 24),
        AsyncRequestView<YHeightDiffResponse>(
          requestId: 'y_height_diff',
          value: dataAsync,
          loadingLabel: '載入高度差資料…',
          isEmpty: (response) => response.isEmpty,
          emptyBuilder: (_) => const _YHeightDiffEmpty(),
          onRetry: () => ref.invalidate(yHeightDiffProvider),
          dataBuilder: (context, response) =>
              _YHeightDiffContent(response: response),
        ),
      ],
    );
  }
}

class _YHeightDiffContent extends StatefulWidget {
  const _YHeightDiffContent({required this.response});

  final YHeightDiffResponse response;

  @override
  State<_YHeightDiffContent> createState() => _YHeightDiffContentState();
}

class _YHeightDiffContentState extends State<_YHeightDiffContent> {
  HeightUnit _unit = HeightUnit.cm;

  @override
  Widget build(BuildContext context) {
    final response = widget.response;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YHeightDiffMetrics(
          response: response,
          unit: _unit,
        ),
        const SizedBox(height: 16),
        YHeightDiffChartSection(
          response: response,
          unit: _unit,
          onUnitChanged: (unit) => setState(() => _unit = unit),
        ),
      ],
    );
  }
}

class _YHeightDiffEmpty extends StatelessWidget {
  const _YHeightDiffEmpty();

  @override
  Widget build(BuildContext context) {
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
            '尚無高度差資料',
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請確認 session 已完成 Extract 並存在對應的骨架資料。',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
