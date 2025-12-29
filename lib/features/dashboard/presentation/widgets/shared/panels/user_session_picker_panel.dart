import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/user_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/delete_user_dialog.dart';

/// 在 Session Picker 內嵌的「依使用者挑選 session」面板。
///
/// 左側：使用者清單（支援關鍵字搜尋 + 分頁載入）
/// 右側：選定使用者的 sessions/bag 預覽（點選 session 直接回傳）
class UserSessionPickerPanel extends ConsumerStatefulWidget {
  const UserSessionPickerPanel({
    required this.onSelectSession,
    super.key,
  });

  final ValueChanged<String> onSelectSession;

  @override
  ConsumerState<UserSessionPickerPanel> createState() =>
      _UserSessionPickerPanelState();
}

class _UserSessionPickerPanelState extends ConsumerState<UserSessionPickerPanel> {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  Timer? _debounceTimer;

  final List<UserListItem> _items = [];
  UserListItem? _selectedUser;
  int _listRequestId = 0;

  // list paging
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 20;
  int _totalPages = 0;
  String? _error;
  String _keyword = '';

  // preview (user detail)
  bool _isPreviewLoading = false;
  String? _previewError;
  UserDetailResponse? _preview;

  bool _isDeleteUserBusy = false;

  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _prepareSearchAndShowLoading('');
    _fetchFirstPageForCurrentQuery();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void refresh() {
    _prepareSearchAndShowLoading(_keyword);
    _fetchFirstPageForCurrentQuery();
  }

  void _onScroll() {
    // 已有明確分頁 UI 時，避免無限滾動造成「一頁資料被 append 成多頁」而難以理解。
    if (_totalPages > 0) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  int get _currentPage {
    final total = _totalPages <= 0 ? 1 : _totalPages;
    return (_page - 1).clamp(1, total);
  }

  Future<void> _goToPage(int targetPage) async {
    final next = targetPage.clamp(1, _totalPages <= 0 ? 1 : _totalPages);
    if (_isLoading || next == _currentPage) {
      return;
    }

    final requestId = ++_listRequestId;
    final keywordSnapshot = _keyword;

    setState(() {
      _items.clear();
      _selectedUser = null;
      _preview = null;
      _previewError = null;
      _isPreviewLoading = false;
      _isLoading = true;
      _error = null;
    });

    try {
      if (keywordSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot,
          page: next,
          pageSize: _pageSize,
        );
        if (!mounted || requestId != _listRequestId) return;
        setState(() {
          _items.addAll(
            result.items.map(
              (e) => UserListItem(
                userCode: e.userCode,
                name: e.name,
                createdAt: e.createdAt,
                updatedAt: e.createdAt,
              ),
            ),
          );
          _totalPages = result.totalPages;
          _hasMore = result.canLoadMore;
          _page = result.page + 1;
          _isLoading = false;
        });
      } else {
        final result = await _repo.fetchUserList(page: next, pageSize: _pageSize);
        if (!mounted || requestId != _listRequestId) return;
        setState(() {
          _items.addAll(result.items);
          _totalPages = result.totalPages;
          _hasMore = result.canLoadMore;
          _page = result.page + 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Widget _buildPaginationFooter() {
    final total = _totalPages;
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final colors = context.colorScheme;
    final current = _currentPage;

    final pageSet = <int>{1, total, current - 1, current, current + 1}
        .where((p) => p >= 1 && p <= total)
        .toList()
      ..sort();

    final pageButtons = <Widget>[];
    int? last;
    for (final p in pageSet) {
      if (last != null && p - last > 1) {
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('…', style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          ),
        );
      }
      final selected = p == current;
      pageButtons.add(
        OutlinedButton(
          onPressed: _isLoading || selected ? null : () => _goToPage(p),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(40, 36),
            backgroundColor:
                selected ? colors.primary.withValues(alpha: 0.12) : null,
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Text('$p', style: const TextStyle(fontSize: 12)),
        ),
      );
      last = p;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              IconButton(
                tooltip: '上一頁',
                onPressed: _isLoading || current <= 1
                    ? null
                    : () => _goToPage(current - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: pageButtons,
                  ),
                ),
              ),
              IconButton(
                tooltip: '下一頁',
                onPressed: _isLoading || current >= total
                    ? null
                    : () => _goToPage(current + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final next = _searchController.text.trim();
    if (next != _keyword) {
      _prepareSearchAndShowLoading(next);
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      final stable = _searchController.text.trim();
      _prepareSearchAndShowLoading(stable);
      _fetchFirstPageForCurrentQuery();
    });
  }

  void _prepareSearchAndShowLoading(String keyword) {
    final normalized = keyword.trim();
    _listRequestId++;

    setState(() {
      _keyword = normalized;
      _items.clear();
      _selectedUser = null;
      _preview = null;
      _previewError = null;
      _isPreviewLoading = false;
      _page = 1;
      _totalPages = 0;
      // keyword 非空時改走 /users/search（支援分頁）。
      _hasMore = true;
      _isLoading = true;
      _error = null;
    });
  }

  Future<void> _fetchFirstPageForCurrentQuery() async {
    final requestId = _listRequestId;
    final keywordSnapshot = _keyword;

    try {
      if (keywordSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot,
          page: 1,
          pageSize: _pageSize,
        );
        if (!mounted || requestId != _listRequestId) return;
        setState(() {
          _items.addAll(
            result.items.map(
              (e) => UserListItem(
                userCode: e.userCode,
                name: e.name,
                createdAt: e.createdAt,
                updatedAt: e.createdAt,
              ),
            ),
          );
          _totalPages = result.totalPages;
          _hasMore = result.canLoadMore;
          _page = result.page + 1;
          _isLoading = false;
        });
        return;
      }

      final result = await _repo.fetchUserList(page: 1, pageSize: _pageSize);
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _items.addAll(result.items);
        _hasMore = result.canLoadMore;
        _page = _hasMore ? 2 : 1;
        _totalPages = result.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requestId = _listRequestId;
      final keywordSnapshot = _keyword;

      if (keywordSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot,
          page: _page,
          pageSize: _pageSize,
        );
        if (!mounted || requestId != _listRequestId) return;

        setState(() {
          _items.addAll(
            result.items.map(
              (e) => UserListItem(
                userCode: e.userCode,
                name: e.name,
                createdAt: e.createdAt,
                updatedAt: e.createdAt,
              ),
            ),
          );
          _totalPages = result.totalPages;
          _hasMore = result.canLoadMore;
          _page = result.page + 1;
          _isLoading = false;
        });
        return;
      }

      final result = await _repo.fetchUserList(page: _page, pageSize: _pageSize);
      if (!mounted || requestId != _listRequestId) return;

      setState(() {
        _items.addAll(result.items);
        _hasMore = result.canLoadMore;
        if (_hasMore) {
          _page++;
        }
        _totalPages = result.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectUser(UserListItem item) async {
    if (_selectedUser?.userCode == item.userCode && _preview != null) {
      return;
    }

    setState(() {
      _selectedUser = item;
      _isPreviewLoading = true;
      _previewError = null;
      _preview = null;
    });

    try {
      final detail = await _repo.fetchUserDetail(userCode: item.userCode);
      if (!mounted) return;
      setState(() {
        _preview = detail;
        _isPreviewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreviewLoading = false;
        _previewError = e.toString();
      });
    }
  }

  Future<void> _deleteSelectedUser() async {
    final selected = _selectedUser;
    final preview = _preview;
    if (selected == null || preview == null || _isDeleteUserBusy) {
      return;
    }

    final result = await DeleteUserDialog.show(
      context,
      userName: preview.user.name,
      userCode: preview.user.userCode,
    );
    if (!mounted || result == null) {
      return;
    }

    setState(() => _isDeleteUserBusy = true);
    try {
      final response = await _repo.deleteUser(
        userCode: selected.userCode,
        deleteSessions: result.deleteSessions,
      );
      if (!mounted) return;

      // 先把本地列表移除，避免 UI 一瞬間還顯示已刪除項目。
      setState(() {
        _items.removeWhere((e) => e.userCode == selected.userCode);
        _selectedUser = null;
        _preview = null;
        _previewError = null;
        _isPreviewLoading = false;
      });

      DashboardToast.show(
        context,
        message:
            '已刪除使用者：${preview.user.name}（unlinked=${response.unlinkedSessions}, deleted=${response.deletedSessions}）',
        variant: DashboardToastVariant.success,
      );

      // 重新載入目前頁數，讓總頁數/頁碼同步。
      await _goToPage(_currentPage);
    } catch (e) {
      if (!mounted) return;
      DashboardToast.show(
        context,
        message: '刪除失敗：$e',
        variant: DashboardToastVariant.danger,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isDeleteUserBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isWide = context.isTabletWide;
    final showPagingInfo = _items.isNotEmpty && _totalPages > 0;

    final searchBar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAutocompleteField(
          controller: _searchController,
          labelText: '使用者姓名',
          hintText: '輸入姓名以搜尋，點選使用者後可預覽其 sessions',
          helperText: '提示：輸入姓名可縮小範圍；點選左側使用者可預覽右側 sessions；用下方頁碼切換頁數。',
          maxSuggestions: 10,
        ),
      ],
    );

    final listPane = Container(
      decoration: BoxDecoration(
        color: context.isDark ? colors.surfaceContainerLow : colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '使用者',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                          '第 ${(_page - 1).clamp(1, _totalPages)} / 共 $_totalPages 頁',
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '${_items.length} 筆',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: _items.isEmpty && !_isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error != null ? '載入失敗：$_error' : '沒有資料',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: _items.length + (_isLoading ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: colors.outlineVariant),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final item = _items[index];
                      final selected = _selectedUser?.userCode == item.userCode;
                      return ListTile(
                        selected: selected,
                        leading: CircleAvatar(
                          backgroundColor: colors.surfaceContainerHigh,
                          child: Text(
                            item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.userCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        trailing: Icon(
                          selected ? Icons.check_circle : Icons.chevron_right,
                          size: 18,
                          color: selected
                              ? DashboardAccentColors.of(context).success
                              : colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        onTap: () => _selectUser(item),
                      );
                    },
                  ),
          ),
          _buildPaginationFooter(),
        ],
      ),
    );

    final previewPane = Container(
      decoration: BoxDecoration(
        color: context.isDark ? colors.surfaceContainerLow : colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _selectedUser == null
            ? Center(
                child: Text(
                  '點選左側使用者以預覽其 sessions',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            : _isPreviewLoading
                ? const Center(child: CircularProgressIndicator())
                : _previewError != null
                    ? Center(
                        child: Text(
                          '載入失敗：$_previewError',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : (_preview == null)
                        ? Center(
                            child: Text(
                              '沒有資料',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          )
                        : _UserSessionsPreview(
                            detail: _preview!,
                            onSelectSession: widget.onSelectSession,
                            onDeleteUser: _isDeleteUserBusy
                                ? null
                                : _deleteSelectedUser,
                          ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchBar,
        const SizedBox(height: 12),
        Expanded(
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 4, child: listPane),
                    const SizedBox(width: 12),
                    Expanded(flex: 6, child: previewPane),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: listPane),
                    const SizedBox(height: 12),
                    Expanded(child: previewPane),
                  ],
                ),
        ),
      ],
    );
  }
}

class _UserSessionsPreview extends StatelessWidget {
  const _UserSessionsPreview({
    required this.detail,
    required this.onSelectSession,
    required this.onDeleteUser,
  });

  final UserDetailResponse detail;
  final ValueChanged<String> onSelectSession;
  final VoidCallback? onDeleteUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final sessions = detail.sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                detail.user.name,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                '${sessions.length} sessions',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '刪除使用者',
              onPressed: onDeleteUser,
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                foregroundColor: DashboardAccentColors.of(context).danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          detail.user.userCode,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                '此使用者尚未綁定任何 session(bag)。',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 160,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final item = sessions[index];
                return _SimpleSessionCard(
                  sessionName: item.sessionName,
                  bagPath: item.bagPath,
                  createdAt: item.createdAt,
                  onTap: () => onSelectSession(item.sessionName),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SimpleSessionCard extends StatelessWidget {
  const _SimpleSessionCard({
    required this.sessionName,
    required this.bagPath,
    required this.createdAt,
    required this.onTap,
  });

  final String sessionName;
  final String bagPath;
  final DateTime createdAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Material(
      color: isDark ? const Color(0xFF111111) : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colors.onSurface.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222222)
                      : colors.surfaceContainerHighest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                sessionName,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                bagPath,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${createdAt.toLocal()}'.split('.').first,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


