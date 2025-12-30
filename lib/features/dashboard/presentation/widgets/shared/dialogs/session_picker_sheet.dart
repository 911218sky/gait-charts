import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/delete_session_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/panels/user_session_picker_panel.dart';
import 'package:intl/intl.dart';

/// 以 Dialog 呈現 session 列表並支援搜尋 / 分頁。
class SessionPickerDialog extends ConsumerStatefulWidget {
  const SessionPickerDialog({
    super.key,
    this.excludeUserCode,
    this.enableUserPicker = true,
    this.filterHasVideo = false,
  });

  /// 若不為空，代表 sessions 清單會排除該 user_code（常用於「綁定」時避免選到已綁定的項目）。
  final String? excludeUserCode;

  /// 是否顯示 Users 分頁（依使用者預覽其 sessions）。
  ///
  /// 使用情境：
  /// - 分析頁：需要「先選使用者，再挑 session」時可開啟。
  /// - 使用者綁定頁：只需要挑 session（排除已綁定者）時可關閉，避免多一層 user 預覽造成混淆。
  final bool enableUserPicker;

  /// 是否只顯示有影片的 sessions。
  final bool filterHasVideo;

  @override
  ConsumerState<SessionPickerDialog> createState() =>
      _SessionPickerDialogState();

  static Future<String?> show(
    BuildContext context, {
    String? excludeUserCode,
    bool enableUserPicker = true,
    bool filterHasVideo = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => SessionPickerDialog(
        excludeUserCode: excludeUserCode,
        enableUserPicker: enableUserPicker,
        filterHasVideo: filterHasVideo,
      ),
    );
  }

  /// 專門給影片播放用的 session picker，回傳完整的 session 資訊。
  static Future<RealsenseSessionItem?> showForVideo(BuildContext context) {
    return showDialog<RealsenseSessionItem>(
      context: context,
      builder: (_) => const _VideoSessionPickerDialog(),
    );
  }
}

enum _SessionPickerView { sessions, users }

/// 初始化時自動載入 session 列表並處理 UI 邏輯。
class _SessionPickerDialogState extends ConsumerState<SessionPickerDialog> {
  bool _requested = false;
  _SessionPickerView _view = _SessionPickerView.sessions;

  final GlobalKey<_UserPanelHostState> _userPanelKey =
      GlobalKey<_UserPanelHostState>();

  void _clearUserFilter() {
    // 這裡不 await：UI 點擊事件不需要等待，並避免在 build 內建立 lambda（tear-off）。
    ref.read(sessionListProvider.notifier).clearUserFilterAndReload();
  }

  Future<void> _handleDeleteSession(RealsenseSessionItem item) async {
    final confirmed = await DeleteSessionDialog.show(
      context,
      sessionName: item.sessionName,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final notifier = ref.read(sessionListProvider.notifier);
    try {
      final response = await notifier.deleteSession(
        sessionName: item.sessionName,
      );
      if (!mounted || response == null) {
        return;
      }

      final details = <String>[
        'npy=${response.deletedNpy ? 'deleted' : 'kept'}',
        'bag=${response.deletedBag ? 'deleted' : 'kept'}',
      ];
      final suffix = ' (${details.join(', ')})';

      DashboardToast.show(
        context,
        message: '已刪除 Session：${response.sessionName}$suffix',
        variant: DashboardToastVariant.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      DashboardToast.show(
        context,
        message: '刪除失敗：$error',
        variant: DashboardToastVariant.danger,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(sessionListProvider.notifier);
        final excludeCode = widget.excludeUserCode?.trim();
        if (excludeCode != null && excludeCode.isNotEmpty) {
          notifier.setExcludeUserCodeAndReload(excludeCode);
        } else {
          notifier.fetchFirstPage(force: true);
        }
      });
    }
  }

  void _selectSessionAndClose(String sessionName) {
    final normalized = sessionName.trim();
    if (normalized.isEmpty) {
      return;
    }
    context.navigator.pop(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionListProvider);
    final notifier = ref.read(sessionListProvider.notifier);

    final colors = context.colorScheme;
    // 亮色：用 Zinc100 當 dialog 底，讓內部白色卡片更有層次；深色維持 dark surface。
    final backgroundColor =
        context.isDark ? colors.surface : colors.surfaceContainer;
    // 內部卡片/格子統一用更「白」的層級（light=白、dark=dark surface low）。
    final surfaceColor = colors.surfaceContainerLow;
    final borderColor = colors.outlineVariant;
    final userFilter = state.userFilter;
    final showPagingInfo =
        _view == _SessionPickerView.sessions && state.totalPages > 0;
    final useExplicitPaging = _view == _SessionPickerView.sessions &&
        userFilter == null &&
        state.totalPages > 0;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
      backgroundColor: backgroundColor,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Session',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '選擇一個 Session 以載入分析數據',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Sessions'),
                        selected: _view == _SessionPickerView.sessions,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => _view = _SessionPickerView.sessions);
                        },
                      ),
                      if (widget.enableUserPicker)
                        ChoiceChip(
                          label: const Text('Users'),
                          selected: _view == _SessionPickerView.users,
                          onSelected: (selected) {
                            if (!selected) return;
                            setState(() => _view = _SessionPickerView.users);
                          },
                        ),
                      if (_view == _SessionPickerView.sessions &&
                          userFilter != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.outlineVariant),
                            color: colors.surfaceContainerLow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                userFilter.name,
                                style: context.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 6),
                              AppTooltip(
                                message: '清除使用者篩選',
                                child: InkWell(
                                  onTap: state.isLoading
                                      ? null
                                      : _clearUserFilter,
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (showPagingInfo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.outlineVariant),
                            color: colors.surfaceContainerLow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.layers_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '第 ${state.page} / 共 ${state.totalPages} 頁',
                                style: context.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            AppTooltip(
              message: '重新整理',
              child: IconButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (_view == _SessionPickerView.sessions ||
                            !widget.enableUserPicker) {
                          notifier.fetchFirstPage(force: true);
                        } else {
                          _userPanelKey.currentState?.refresh();
                        }
                      },
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  foregroundColor: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => context.navigator.pop(),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                foregroundColor: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: (_view == _SessionPickerView.users && widget.enableUserPicker)
          ? _UserPanelHost(
              key: _userPanelKey,
              onSelectSession: _selectSessionAndClose,
            )
          : (state.isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null && state.items.isEmpty
                  ? _ErrorView(
                      error: state.error!,
                      onRetry: () => notifier.fetchFirstPage(force: true),
                    )
                  : state.items.isEmpty
                      ? const _EmptyView()
                      : _SessionGrid(
                          state: state,
                          notifier: notifier,
                          backgroundColor: surfaceColor,
                          borderColor: borderColor,
                          onDelete: _handleDeleteSession,
                          useExplicitPaging: useExplicitPaging,
                          filterHasVideo: widget.filterHasVideo,
                        )),
      footer: useExplicitPaging
          ? DashboardPaginationFooter(
              currentPage: state.page <= 0 ? 1 : state.page,
              totalPages: state.totalPages,
              isLoading: state.isLoading,
              onSelectPage: notifier.goToPage,
            )
          : null,
    );
  }
}

class _UserPanelHost extends ConsumerStatefulWidget {
  const _UserPanelHost({required this.onSelectSession, super.key});

  final ValueChanged<String> onSelectSession;

  @override
  ConsumerState<_UserPanelHost> createState() => _UserPanelHostState();
}

class _UserPanelHostState extends ConsumerState<_UserPanelHost> {
  void refresh() {
    // 透過 rebuild 觸發內部 state refresh（避免外部直接依賴其 state 類型）。
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: UserSessionPickerPanel(onSelectSession: widget.onSelectSession),
    );
  }
}

/// 顯示 session 卡片的 Grid，並在滾動到底時載入更多。
class _SessionGrid extends StatelessWidget {
  const _SessionGrid({
    required this.state,
    required this.notifier,
    required this.backgroundColor,
    required this.borderColor,
    required this.onDelete,
    required this.useExplicitPaging,
    this.filterHasVideo = false,
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
    // 若啟用影片過濾，只顯示有影片的 sessions
    final filteredItems = filterHasVideo
        ? state.items.where((item) => item.hasVideo).toList()
        : state.items;

    if (filteredItems.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filterHasVideo ? Icons.videocam_off_outlined : Icons.inbox,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              filterHasVideo ? '沒有包含影片的 Sessions' : 'No sessions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (filterHasVideo) ...[
              const SizedBox(height: 8),
              Text(
                '只有在提取時啟用影片輸出的 sessions 才會有影片',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final grid = GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 160, // 固定高度
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
        return _SessionCard(
          item: item,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          onSelect: () => context.navigator.pop(item.sessionName),
          onDelete: () => onDelete(item),
          isDeleting: state.isDeleting(item.sessionName),
        );
      },
    );

    if (useExplicitPaging) {
      return grid;
    }

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

/// 單一 session 的卡片與 hover 效果。
class _SessionCard extends StatefulWidget {
  const _SessionCard({
    required this.item,
    required this.backgroundColor,
    required this.borderColor,
    required this.onSelect,
    required this.onDelete,
    required this.isDeleting,
  });

  final RealsenseSessionItem item;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

/// 控制 session 卡片的 hover 動畫。
class _SessionCardState extends State<_SessionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    final createdAt = widget.item.createdAt != null
        ? DateFormat(
            'yyyy/MM/dd HH:mm',
          ).format(widget.item.createdAt!.toLocal())
        : 'Unknown Date';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(
                  color: _isHovered
                      ? colors.primary
                      : widget.borderColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : colors.primary.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          size: 16,
                          color: context.isDark ? Colors.white : colors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (widget.isDeleting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_isHovered) ...[
                        AppTooltip(
                          message: '刪除 Session',
                          child: IconButton(
                            onPressed: widget.onDelete,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            style: IconButton.styleFrom(
                              foregroundColor: colors.onSurface,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: colors.onSurface,
                        ),
                      ],
                    ],
                  ),
              const SizedBox(height: 12),
              Text(
                widget.item.sessionName,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                widget.item.bagPath,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                createdAt,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        // 右上角影片緞帶標示
        if (widget.item.hasVideo)
          Positioned(
            top: 0,
            right: 0,
            child: _VideoRibbon(colors: colors),
          ),
          ],
        ),
      ),
    );
  }
}

/// 右上角的影片緞帶標示。
class _VideoRibbon extends StatelessWidget {
  const _VideoRibbon({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          size: 18,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}

/// 在資料抓取失敗時顯示錯誤與重試按鈕。
class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load sessions',
            style: context.textTheme.titleMedium?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// 當沒有 session 資料時顯示的占位畫面。
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 48, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No sessions found',
            style: context.textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 專門給影片播放用的 session picker，回傳完整的 [RealsenseSessionItem]。
class _VideoSessionPickerDialog extends ConsumerStatefulWidget {
  const _VideoSessionPickerDialog();

  @override
  ConsumerState<_VideoSessionPickerDialog> createState() =>
      _VideoSessionPickerDialogState();
}

class _VideoSessionPickerDialogState
    extends ConsumerState<_VideoSessionPickerDialog> {
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
      header: Padding(
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
      ),
      body: state.isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
              ? _ErrorView(
                  error: state.error!,
                  onRetry: () => notifier.fetchFirstPage(force: true),
                )
              : state.items.isEmpty
                  ? const _EmptyView()
                  : _VideoSessionGrid(
                      state: state,
                      notifier: notifier,
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
}

/// 影片 session 選擇用的 Grid。
class _VideoSessionGrid extends StatelessWidget {
  const _VideoSessionGrid({
    required this.state,
    required this.notifier,
    required this.backgroundColor,
    required this.borderColor,
    required this.onSelect,
  });

  final SessionListState state;
  final SessionListNotifier notifier;
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
        final hasVideo = item.hasVideo;

        return _VideoSessionCard(
          item: item,
          hasVideo: hasVideo,
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
        ? DateFormat('yyyy/MM/dd HH:mm').format(widget.item.createdAt!.toLocal())
        : 'Unknown Date';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
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
                  Row(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: colors.onSurface,
                        ),
                    ],
                  ),
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
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // 右上角影片緞帶標示
            if (widget.hasVideo)
              Positioned(
                top: 0,
                right: 0,
                child: _VideoRibbon(colors: colors),
              ),
          ],
        ),
      ),
    );
  }
}
