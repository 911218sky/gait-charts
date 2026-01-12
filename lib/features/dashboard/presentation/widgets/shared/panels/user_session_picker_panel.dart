import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/users/users_state.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/user_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/panels/user_session_picker/user_session_picker.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/delete_user_dialog.dart';

/// 在 Session Picker 內嵌的「依使用者挑選 session」面板。
///
/// 左側：使用者清單（支援關鍵字搜尋 + 分頁載入）
/// 右側：選定使用者的 sessions/bag 預覽（點選 session 直接回傳）
class UserSessionPickerPanel extends ConsumerStatefulWidget {
  const UserSessionPickerPanel({required this.onSelectSession, super.key});

  final ValueChanged<String> onSelectSession;

  @override
  ConsumerState<UserSessionPickerPanel> createState() =>
      _UserSessionPickerPanelState();
}

class _UserSessionPickerPanelState
    extends ConsumerState<UserSessionPickerPanel> {
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
  final List<String> _selectedCohorts = [];

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

  void _toggleCohort(String cohort) {
    final label = cohort.trim();
    if (label.isEmpty) {
      return;
    }
    setState(() {
      if (_selectedCohorts.contains(label)) {
        _selectedCohorts.remove(label);
      } else {
        if (_selectedCohorts.length >= 3) {
          DashboardToast.show(
            context,
            message: '最多只能選 3 個族群',
            variant: DashboardToastVariant.warning,
          );
          return;
        }
        _selectedCohorts.add(label);
      }
      _prepareSearchAndShowLoading(_keyword);
    });
    _fetchFirstPageForCurrentQuery();
  }

  void _clearCohorts() {
    if (_selectedCohorts.isEmpty) return;
    setState(() {
      _selectedCohorts.clear();
      _prepareSearchAndShowLoading(_keyword);
    });
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
    final cohortSnapshot = List<String>.from(_selectedCohorts);

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
      if (keywordSnapshot.isNotEmpty || cohortSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot.isNotEmpty ? keywordSnapshot : null,
          cohorts: cohortSnapshot,
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
                cohort: e.cohort,
              ),
            ),
          );
          _totalPages = result.totalPages;
          _hasMore = result.canLoadMore;
          _page = result.page + 1;
          _isLoading = false;
        });
      } else {
        final result = await _repo.fetchUserList(
          page: next,
          pageSize: _pageSize,
        );
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

    final pageSet = <int>{
      1,
      total,
      current - 1,
      current,
      current + 1,
    }.where((p) => p >= 1 && p <= total).toList()..sort();

    final pageButtons = <Widget>[];
    int? last;
    for (final p in pageSet) {
      if (last != null && p - last > 1) {
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '…',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
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
            backgroundColor: selected
                ? colors.primary.withValues(alpha: 0.12)
                : null,
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
      // keyword/cohort 有任一存在時改走 /users/search（支援分頁）。
      _hasMore = true;
      _isLoading = true;
      _error = null;
    });
  }

  Future<void> _fetchFirstPageForCurrentQuery() async {
    final requestId = _listRequestId;
    final keywordSnapshot = _keyword;
    final cohortSnapshot = List<String>.from(_selectedCohorts);

    try {
      if (keywordSnapshot.isNotEmpty || cohortSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot.isNotEmpty ? keywordSnapshot : null,
          cohorts: cohortSnapshot,
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
                cohort: e.cohort,
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
      final cohortSnapshot = List<String>.from(_selectedCohorts);

      if (keywordSnapshot.isNotEmpty || cohortSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot.isNotEmpty ? keywordSnapshot : null,
          cohorts: cohortSnapshot,
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
                cohort: e.cohort,
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

      final result = await _repo.fetchUserList(
        page: _page,
        pageSize: _pageSize,
      );
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
      if (mounted) {
        setState(() => _isDeleteUserBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isWide = context.isTabletWide;
    final showPagingInfo = _items.isNotEmpty && _totalPages > 0;
    final cohortsAsync = ref.watch(userCohortsProvider(false));
    final cohortStats = cohortsAsync.maybeWhen(
      data: (r) => r.cohorts,
      orElse: () => const <UserCohortStat>[],
    );
    final suggested = [...cohortStats]
      ..sort((a, b) => b.userCount.compareTo(a.userCount));
    final topCohorts = suggested.take(10).toList(growable: false);
    final isDark = context.isDark;

    FilterChip buildCohortChip(String label, {int? count}) {
      final selected = _selectedCohorts.contains(label);
      final bg = isDark ? colors.surfaceContainerLow : colors.surface;
      final selectedBg = colors.primary.withValues(alpha: isDark ? 0.18 : 0.12);
      final fg = selected ? colors.onSurface : colors.onSurfaceVariant;
      return FilterChip(
        label: Text(count != null ? '$label ($count)' : label),
        selected: selected,
        onSelected: (_) => _toggleCohort(label),
        backgroundColor: bg,
        selectedColor: selectedBg,
        showCheckmark: true,
        checkmarkColor: colors.primary,
        labelStyle: TextStyle(
          color: fg,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      );
    }

    final searchBar = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAutocompleteField(
          controller: _searchController,
          labelText: '使用者姓名',
          hintText: '輸入姓名以搜尋，或用族群篩選',
          helperText: _selectedCohorts.isEmpty
              ? '提示：輸入姓名可縮小範圍；也可用族群篩選（最多 3 個）；點選左側使用者可預覽右側 sessions；用下方頁碼切換頁數。'
              : '目前篩選：${_selectedCohorts.join('、')}（最多 3 個）',
          maxSuggestions: 10,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.groups_rounded,
              size: 16,
              color: colors.onSurfaceVariant.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '族群篩選（最多 3 個）',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
            if (_selectedCohorts.isNotEmpty)
              TextButton.icon(
                onPressed: _clearCohorts,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('清除'),
              ),
            if (cohortsAsync.isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (topCohorts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in topCohorts)
                buildCohortChip(s.cohort, count: s.userCount),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              buildCohortChip('正常人'),
              buildCohortChip('中風'),
              buildCohortChip('高齡'),
            ],
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
                    separatorBuilder: (_, _) =>
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
                            item.name.isNotEmpty
                                ? item.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.userCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (item.cohort.isNotEmpty)
                              Text(
                                item.cohort.join('、'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                          ],
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
            : UserSessionsPreview(
                detail: _preview!,
                onSelectSession: widget.onSelectSession,
                onDeleteUser: _isDeleteUserBusy ? null : _deleteSelectedUser,
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
