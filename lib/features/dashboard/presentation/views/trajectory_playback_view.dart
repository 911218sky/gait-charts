import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/trajectory/trajectory_config_panel.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/trajectory/trajectory_player_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/trajectory/trajectory_simple_header.dart';

/// 顯示「以點位重建」的 top-down 行走軌跡影片（前端 Canvas 播放）。
///
/// 佈局：
/// - Top: [TrajectorySimpleHeader] (Session Input)
/// - Body: [TrajectoryPlayerCard] (Left/Center) + [TrajectoryConfigPanel] (Right)
class TrajectoryPlaybackView extends ConsumerWidget {
  const TrajectoryPlaybackView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(trajectoryPayloadProvider);
    final failure = ref.watch(requestFailureProvider('trajectory_payload'));
    final isLoading = dataAsync.isLoading && failure == null;
    final isCompact = context.isTrajectoryCompact;

    void openConfigSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
                child: const TrajectoryConfigPanel(
                  width: null,
                  showSidebarBorder: false,
                ),
              ),
            ),
          );
        },
      );
    }

    void handleLoad() {
      // 「載入軌跡」視為 retry：清除 failure gate，並刷新 provider。
      ref.read(requestFailureStoreProvider.notifier).clearFailure(
            'trajectory_payload',
          );
      onLoadSession();
      ref.invalidate(trajectoryPayloadProvider);
    }

    return Column(
      children: [
        TrajectorySimpleHeader(
          sessionController: sessionController,
          onLoadSession: handleLoad,
          isLoading: isLoading,
          onOpenConfig: isCompact ? openConfigSheet : null,
        ),
        Expanded(
          child: isCompact
              ? _TrajectoryPlayerPane(
                  dataAsync: dataAsync,
                  onRetry: () => ref.invalidate(trajectoryPayloadProvider),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TrajectoryPlayerPane(
                        dataAsync: dataAsync,
                        onRetry: () => ref.invalidate(trajectoryPayloadProvider),
                      ),
                    ),
                    const TrajectoryConfigPanel(),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TrajectoryPlayerPane extends StatelessWidget {
  const _TrajectoryPlayerPane({
    required this.dataAsync,
    required this.onRetry,
  });

  final AsyncValue<TrajectoryDecodedPayload> dataAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final pad = context.isMobile ? 16.0 : 24.0;

    return Container(
      // 淺色模式避免用黑色半透明蓋底，會變成大片髒灰。
      // 改用 theme 的 surfaceContainer 做出「柔和分區」。
      color: isDark ? Colors.black.withValues(alpha: 0.2) : colors.surfaceContainerLow,
      padding: EdgeInsets.all(pad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
            maxHeight: 700,
          ),
          child: AsyncRequestView(
            requestId: 'trajectory_payload',
            value: dataAsync,
            loadingLabel: '載入軌跡資料…',
            isEmpty: (data) => data.nFrames <= 0,
            emptyBuilder: (_) => const _TrajectoryEmpty(),
            onRetry: onRetry,
            dataBuilder: (context, payload) => TrajectoryPlayerCard(payload: payload),
          ),
        ),
      ),
    );
  }
}

class _TrajectoryEmpty extends StatelessWidget {
  const _TrajectoryEmpty();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    return Container(
      width: double.infinity,
      height: 400,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            size: 64,
            color: context.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '尚無軌跡資料',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請輸入 Session 名稱並點擊「載入軌跡」',
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
