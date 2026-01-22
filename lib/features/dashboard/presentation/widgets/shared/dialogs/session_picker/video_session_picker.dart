import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

import 'state_views.dart';
import 'video_ribbon.dart';

/// 專門給影片播放用的 session picker，回傳完整的 [RealsenseSessionItem]。
class VideoSessionPickerDialog extends ConsumerStatefulWidget {
  const VideoSessionPickerDialog({super.key});

  @override
  ConsumerState<VideoSessionPickerDialog> createState() =>
      _VideoSessionPickerDialogState();
}

class _VideoSessionPickerDialogState
    extends ConsumerState<VideoSessionPickerDialog> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sessionListProvider.notifier).fetchFirstPage(force: true);
      });
    }
  }

  void _selectSession(RealsenseSessionItem item) {
    context.navigator.pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionListProvider);
    final notifier = ref.read(sessionListProvider.notifier);
    final colors = context.colorScheme;
    final backgroundColor =
        context.isDark ? colors.surface : colors.surfaceContainer;
    final surfaceColor = colors.surfaceContainerLow;
    final borderColor = colors.outlineVariant;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
      backgroundColor: backgroundColor,
      header: _buildHeader(context, colors, state, notifier),
      body: state.isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
              ? SessionPickerErrorView(
                  error: state.error!,
                  onRetry: () => notifier.fetchFirstPage(force: true),
                )
              : state.items.isEmpty
                  ? const SessionPickerEmptyView()
                  : _VideoSessionGrid(
                      state: state,
                      backgroundColor: surfaceColor,
                      borderColor: borderColor,
                      onSelect: _selectSession,
                    ),
      footer: state.totalPages > 0
          ? DashboardPaginationFooter(
              currentPage: state.page <= 0 ? 1 : state.page,
              totalPages: state.totalPages,
              isLoading: state.isLoading,
              onSelectPage: notifier.goToPage,
            )
          : null,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colors,
    SessionListState state,
    SessionListNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '選擇影片',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '選擇一個 Session 來播放影片',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppTooltip(
            message: '重新整理',
            child: IconButton(
              onPressed: state.isLoading
                  ? null
                  : () => notifier.fetchFirstPage(force: true),
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(foregroundColor: colors.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.navigator.pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(foregroundColor: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

/// 影片 session 選擇用的 Grid。
class _VideoSessionGrid extends StatelessWidget {
  const _VideoSessionGrid({
    required this.state,
    required this.backgroundColor,
    required this.borderColor,
    required this.onSelect,
  });

  final SessionListState state;
  final Color backgroundColor;
  final Color borderColor;
  final ValueChanged<RealsenseSessionItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _VideoSessionCard(
          item: item,
          hasVideo: item.hasVideo,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          onSelect: () => onSelect(item),
        );
      },
    );
  }
}

/// 影片 session 卡片，有影片的會有標記，沒影片的會顯示灰色。
class _VideoSessionCard extends StatefulWidget {
  const _VideoSessionCard({
    required this.item,
    required this.hasVideo,
    required this.backgroundColor,
    required this.borderColor,
    required this.onSelect,
  });

  final RealsenseSessionItem item;
  final bool hasVideo;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onSelect;

  @override
  State<_VideoSessionCard> createState() => _VideoSessionCardState();
}

class _VideoSessionCardState extends State<_VideoSessionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final createdAt = widget.item.createdAt != null
        ? DateFormat('yyyy/MM/dd HH:mm')
            .format(widget.item.createdAt!.toLocal())
        : 'Unknown Date';

    return MouseRegion(
      onEnter:
          widget.hasVideo ? (_) => setState(() => _isHovered = true) : null,
      onExit:
          widget.hasVideo ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.hasVideo
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.hasVideo ? widget.onSelect : null,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.hasVideo
                    ? widget.backgroundColor
                    : widget.backgroundColor.withValues(alpha: 0.5),
                border: Border.all(
                  color: _isHovered
                      ? (widget.hasVideo ? colors.primary : colors.outline)
                      : widget.borderColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(colors),
                  const SizedBox(height: 12),
                  Text(
                    widget.item.sessionName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.hasVideo
                              ? colors.onSurface
                              : colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    createdAt,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
            if (widget.hasVideo)
              Positioned(
                top: 0,
                right: 0,
                child: VideoRibbon(colors: colors),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.hasVideo
                ? colors.primary.withValues(alpha: 0.15)
                : colors.onSurface.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.hasVideo
                ? Icons.play_circle_outline
                : Icons.videocam_off_outlined,
            size: 16,
            color: widget.hasVideo
                ? colors.primary
                : colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        if (!widget.hasVideo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '無影片',
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        if (widget.hasVideo && _isHovered)
          Icon(Icons.arrow_forward, size: 16, color: colors.onSurface),
      ],
    );
  }
}
