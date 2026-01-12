import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/user_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_browser/user_browser.dart';
import 'package:google_fonts/google_fonts.dart';

/// 瀏覽使用者清單，並提供「預覽」後再選擇。
class UserBrowserDialog extends ConsumerStatefulWidget {
  const UserBrowserDialog({super.key, this.initialQuery});

  /// 初始搜尋關鍵字（通常由主畫面的輸入框帶入）。
  final String? initialQuery;

  @override
  ConsumerState<UserBrowserDialog> createState() => _UserBrowserDialogState();
}

class _UserBrowserDialogState extends ConsumerState<UserBrowserDialog> {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  final List<UserListItem> _items = [];
  UserListItem? _selected;
  int _listRequestId = 0;

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 20;
  int _totalPages = 0;
  String? _error;

  String _keyword = '';

  bool _isPreviewLoading = false;
  String? _previewError;
  UserDetailResponse? _preview;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _keyword = _searchController.text.trim();

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    _prepareSearchAndShowLoading(_keyword);
    _fetchFirstPageForCurrentQuery();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    // 已有明確分頁 UI 時，避免無限滾動造成「一頁資料被 append 成多頁」而難以理解。
    if (_totalPages > 0) return;
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
    if (_isLoading || next == _currentPage) return;

    final requestId = ++_listRequestId;
    final keywordSnapshot = _keyword;

    setState(() {
      _items.clear();
      _selected = null;
      _preview = null;
      _previewError = null;
      _isPreviewLoading = false;
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(dashboardRepositoryProvider);

      if (keywordSnapshot.isNotEmpty) {
        final result = await repo.searchUserSuggestions(
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
        final result =
            await repo.fetchUserList(page: next, pageSize: _pageSize);
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
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
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
      _selected = null;
      _preview = null;
      _previewError = null;
      _isPreviewLoading = false;
      _page = 1;
      _totalPages = 0;
      _hasMore = true;
      _isLoading = true;
      _error = null;
    });
  }

  Future<void> _fetchFirstPageForCurrentQuery() async {
    final requestId = _listRequestId;
    final keywordSnapshot = _keyword;

    try {
      final repo = ref.read(dashboardRepositoryProvider);

      if (keywordSnapshot.isNotEmpty) {
        final result = await repo.searchUserSuggestions(
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

      final result = await repo.fetchUserList(page: 1, pageSize: _pageSize);

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
    if (_isLoading || !_hasMore) return;

    final requestId = _listRequestId;
    final keywordSnapshot = _keyword;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(dashboardRepositoryProvider);
      if (keywordSnapshot.isNotEmpty) {
        final result = await repo.searchUserSuggestions(
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

      final result =
          await repo.fetchUserList(page: _page, pageSize: _pageSize);

      if (!mounted || requestId != _listRequestId) return;

      setState(() {
        _items.addAll(result.items);
        _hasMore = result.canLoadMore;
        if (_hasMore) _page++;
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

  Future<void> _loadPreview(UserListItem item) async {
    setState(() {
      _isPreviewLoading = true;
      _preview = null;
      _previewError = null;
    });

    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final detail = await repo.fetchUserDetail(userCode: item.userCode);

      if (!mounted) return;
      if (_selected?.userCode != item.userCode) return;

      setState(() {
        _preview = detail;
        _isPreviewLoading = false;
        _previewError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_selected?.userCode != item.userCode) return;

      setState(() {
        _isPreviewLoading = false;
        _previewError = e.toString();
      });
    }
  }

  void _select(UserListItem item) {
    if (_selected?.userCode == item.userCode) return;

    setState(() {
      _selected = item;
      _preview = null;
      _previewError = null;
      _isPreviewLoading = false;
    });

    _loadPreview(item);
  }

  Widget _buildPaginationFooter() {
    final total = _totalPages > 0 ? _totalPages : (_items.isNotEmpty ? 1 : 0);
    if (total <= 0) return const SizedBox.shrink();

    final colors = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: colors.outlineVariant),
        DashboardPaginationFooter(
          currentPage: _currentPage,
          totalPages: total,
          isLoading: _isLoading,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          onSelectPage: _goToPage,
        ),
      ],
    );
  }

  Widget _buildListWithBehavior({required bool immediateSelect}) {
    final colors = context.colorScheme;

    if (_items.isEmpty && !_isLoading) {
      if (_error != null) {
        return UserBrowserErrorState(
          error: _error!,
          onRetry: () {
            _prepareSearchAndShowLoading(_keyword);
            _fetchFirstPageForCurrentQuery();
          },
        );
      }
      return UserBrowserEmptyState(hasKeyword: _keyword.isNotEmpty);
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _items.length + (_isLoading ? 1 : 0),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colors.outlineVariant.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
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
        final selected = _selected?.userCode == item.userCode;

        return UserListItemTile(
          item: item,
          isSelected: selected,
          onTap: () => immediateSelect
              ? context.navigator.pop(item)
              : _select(item),
          onDoubleTap:
              immediateSelect ? null : () => context.navigator.pop(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final showPagingInfo = _items.isNotEmpty && _totalPages > 0;
    final isCompactScreen = context.isMobile;

    return DashboardDialogShell(
      constraints: isCompactScreen
          ? const BoxConstraints(
              maxWidth: double.infinity, maxHeight: double.infinity)
          : const BoxConstraints(maxWidth: 1180, maxHeight: 840),
      insetPadding: isCompactScreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      header: _buildHeader(colors, showPagingInfo, isCompactScreen),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          final useSidePreview = constraints.maxWidth >= 860;

          final searchBar = _buildSearchBar(isCompact);
          final listPane = _buildListPane(colors, isCompact);
          final previewPane = UserPreviewPanel(
            selected: _selected,
            preview: _preview,
            isLoading: _isPreviewLoading,
            error: _previewError,
            onRetry: () {
              if (_selected != null) _loadPreview(_selected!);
            },
            onSelect: () {
              if (_selected != null) context.navigator.pop(_selected);
            },
          );

          return Column(
            children: [
              searchBar,
              Divider(height: 1, color: colors.outlineVariant),
              Expanded(
                child: isCompact
                    ? listPane
                    : useSidePreview
                        ? Row(
                            children: [
                              SizedBox(width: 460, child: listPane),
                              VerticalDivider(
                                  width: 1, color: colors.outlineVariant),
                              Expanded(child: previewPane),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(child: listPane),
                              Divider(height: 1, color: colors.outlineVariant),
                              SizedBox(height: 280, child: previewPane),
                            ],
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      ColorScheme colors, bool showPagingInfo, bool isCompactScreen) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      child: Row(
        children: [
          Icon(Icons.people_outline, color: colors.onSurface, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '瀏覽使用者',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          if (showPagingInfo && !isCompactScreen)
            Container(
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
                    '第 ${(_page - 1).clamp(1, _totalPages)} / 共 $_totalPages 頁',
                    style: GoogleFonts.inter(fontSize: 12, color: colors.onSurface),
                  ),
                ],
              ),
            ),
          AppTooltip(
            message: '關閉',
            child: IconButton(
              onPressed: () => context.navigator.pop(),
              icon: Icon(Icons.close, color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isCompact) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAutocompleteField(
            controller: _searchController,
            labelText: '使用者名稱',
            hintText: '輸入姓名或首碼，支援自動完成',
            helperText: isCompact
                ? '提示：輸入可縮小範圍；點一下直接選擇；用下方頁碼切換頁數。'
                : '提示：輸入可縮小範圍；單擊預覽、雙擊選擇；用下方頁碼切換頁數。',
            maxSuggestions: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildListPane(ColorScheme colors, bool isCompact) {
    return Column(
      children: [
        Expanded(child: _buildListWithBehavior(immediateSelect: isCompact)),
        _buildPaginationFooter(),
        if (!isCompact)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '單擊預覽、雙擊選擇。',
                    style: GoogleFonts.inter(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
