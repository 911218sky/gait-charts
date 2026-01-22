import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

import 'session_card.dart';

/// 顯示 session 卡片的 Grid，並在滾動到底時載入更多。
class SessionGrid extends StatelessWidget {
  const SessionGrid({
    required this.state,
    required this.notifier,
    required this.backgroundColor,
    required this.borderColor,
    required this.onDelete,
    required this.useExplicitPaging,
    this.filterHasVideo = false,
    super.key,
  });

  final SessionListState state;
  final SessionListNotifier notifier;
  final Color backgroundColor;
  final Color borderColor;
  final Future<void> Function(RealsenseSessionItem item) onDelete;
  final bool useExplicitPaging;

  /// 是否只顯示有影片的 sessions。
  final bool filterHasVideo;

  @override
  Widget build(BuildContext context) {
    final filteredItems = filterHasVideo
        ? state.items.where((item) => item.hasVideo).toList()
        : state.items;

    if (filteredItems.isEmpty && !state.isLoading) {
      return _EmptyFilteredView(filterHasVideo: filterHasVideo);
    }

    final grid = GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: useExplicitPaging
          ? filteredItems.length
          : filteredItems.length + (state.canLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (!useExplicitPaging && index >= filteredItems.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = filteredItems[index];
        return SessionCard(
          item: item,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          onSelect: () => context.navigator.pop(item.sessionName),
          onDelete: () => onDelete(item),
          isDeleting: state.isDeleting(item.sessionName),
        );
      },
    );

    if (useExplicitPaging) return grid;

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          notifier.loadMore();
        }
        return false;
      },
      child: grid,
    );
  }
}

class _EmptyFilteredView extends StatelessWidget {
  const _EmptyFilteredView({required this.filterHasVideo});

  final bool filterHasVideo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filterHasVideo ? Icons.videocam_off_outlined : Icons.inbox,
            size: 48,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filterHasVideo ? '沒有包含影片的 Sessions' : 'No sessions found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          if (filterHasVideo) ...[
            const SizedBox(height: 8),
            Text(
              '只有在提取時啟用影片輸出的 sessions 才會有影片',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
