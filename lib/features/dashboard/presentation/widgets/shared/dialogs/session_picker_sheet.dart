import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/delete_session_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker/session_picker.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/panels/user_session_picker_panel.dart';

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
      builder: (_) => const VideoSessionPickerDialog(),
    );
  }
}

enum _SessionPickerView { sessions, users }

class _SessionPickerDialogState extends ConsumerState<SessionPickerDialog> {
  bool _requested = false;
  _SessionPickerView _view = _SessionPickerView.sessions;

  final GlobalKey<_UserPanelHostState> _userPanelKey =
      GlobalKey<_UserPanelHostState>();

  void _clearUserFilter() {
    ref.read(sessionListProvider.notifier).clearUserFilterAndReload();
  }

  Future<void> _handleDeleteSession(RealsenseSessionItem item) async {
    final confirmed = await DeleteSessionDialog.show(
      context,
      sessionName: item.sessionName,
    );
    if (!mounted || confirmed != true) return;

    final notifier = ref.read(sessionListProvider.notifier);
    try {
      final response = await notifier.deleteSession(
        sessionName: item.sessionName,
      );
      if (!mounted || response == null) return;

      final details = <String>[
        'npy=${response.deletedNpy ? 'deleted' : 'kept'}',
        'video=${response.deletedVideo ? 'deleted' : 'kept'}',
        'bag=${response.deletedBag ? 'deleted' : 'kept'}',
      ];
      final suffix = ' (${details.join(', ')})';

      DashboardToast.show(
        context,
        message: '已刪除 Session：${response.sessionName}$suffix',
        variant: DashboardToastVariant.success,
      );
    } catch (error) {
      if (!mounted) return;
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
    if (normalized.isEmpty) return;
    context.navigator.pop(normalized);
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
    final userFilter = state.userFilter;
    final showPagingInfo =
        _view == _SessionPickerView.sessions && state.totalPages > 0;
    final useExplicitPaging = _view == _SessionPickerView.sessions &&
        userFilter == null &&
        state.totalPages > 0;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
      backgroundColor: backgroundColor,
      header: _buildHeader(context, colors, state, notifier, userFilter,
          showPagingInfo),
      body: _buildBody(state, notifier, surfaceColor, borderColor,
          useExplicitPaging),
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

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colors,
    SessionListState state,
    SessionListNotifier notifier,
    UserListItem? userFilter,
    bool showPagingInfo,
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
                _buildChips(context, colors, state, userFilter, showPagingInfo),
              ],
            ),
          ),
          _buildHeaderActions(context, colors, state, notifier),
        ],
      ),
    );
  }

  Widget _buildChips(
    BuildContext context,
    ColorScheme colors,
    SessionListState state,
    UserListItem? userFilter,
    bool showPagingInfo,
  ) {
    return Wrap(
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
        if (_view == _SessionPickerView.sessions && userFilter != null)
          _UserFilterChip(
            userFilter: userFilter,
            colors: colors,
            isLoading: state.isLoading,
            onClear: _clearUserFilter,
          ),
        if (showPagingInfo)
          _PagingInfoChip(
            page: state.page,
            totalPages: state.totalPages,
            colors: colors,
          ),
      ],
    );
  }

  Widget _buildHeaderActions(
    BuildContext context,
    ColorScheme colors,
    SessionListState state,
    SessionListNotifier notifier,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    );
  }

  Widget _buildBody(
    SessionListState state,
    SessionListNotifier notifier,
    Color surfaceColor,
    Color borderColor,
    bool useExplicitPaging,
  ) {
    if (_view == _SessionPickerView.users && widget.enableUserPicker) {
      return _UserPanelHost(
        key: _userPanelKey,
        onSelectSession: _selectSessionAndClose,
      );
    }

    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return SessionPickerErrorView(
        error: state.error!,
        onRetry: () => notifier.fetchFirstPage(force: true),
      );
    }

    if (state.items.isEmpty) {
      return const SessionPickerEmptyView();
    }

    return SessionGrid(
      state: state,
      notifier: notifier,
      backgroundColor: surfaceColor,
      borderColor: borderColor,
      onDelete: _handleDeleteSession,
      useExplicitPaging: useExplicitPaging,
      filterHasVideo: widget.filterHasVideo,
    );
  }
}

class _UserFilterChip extends StatelessWidget {
  const _UserFilterChip({
    required this.userFilter,
    required this.colors,
    required this.isLoading,
    required this.onClear,
  });

  final UserListItem userFilter;
  final ColorScheme colors;
  final bool isLoading;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          Text(userFilter.name, style: context.textTheme.bodySmall),
          const SizedBox(width: 6),
          AppTooltip(
            message: '清除使用者篩選',
            child: InkWell(
              onTap: isLoading ? null : onClear,
              child: Icon(
                Icons.close,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagingInfoChip extends StatelessWidget {
  const _PagingInfoChip({
    required this.page,
    required this.totalPages,
    required this.colors,
  });

  final int page;
  final int totalPages;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            '第 $page / 共 $totalPages 頁',
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
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
