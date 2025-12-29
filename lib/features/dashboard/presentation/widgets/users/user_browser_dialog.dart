import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/cards/session_grid_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/user_autocomplete_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
        if (!mounted || requestId != _listRequestId) {
          return;
        }
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
        final result = await repo.fetchUserList(page: next, pageSize: _pageSize);
        if (!mounted || requestId != _listRequestId) {
          return;
        }
        setState(() {
          _items.addAll(result.items);
          _totalPages = result.totalPages;
          _hasMore = result.canLoadMore;
          _page = result.page + 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || requestId != _listRequestId) {
        return;
      }
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
    // 後端若未回 total_pages（或回 0），但已有 items 時，仍顯示 1 頁的分頁列（disabled）。
    final total = _totalPages > 0 ? _totalPages : (_items.isNotEmpty ? 1 : 0);
    if (total <= 0) {
      return const SizedBox.shrink();
    }

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

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final next = _searchController.text.trim();
    if (next != _keyword) {
      // 使用者一輸入就先清空舊資料，避免 debounce 期間還顯示上一筆結果造成「閃一下」。
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

    // 遞增 request id，用於中斷上一筆搜尋請求回來覆蓋 UI。
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
      // keyword 非空時走 /users/search（也支援分頁）。
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

        if (!mounted || requestId != _listRequestId) {
          return;
        }

        setState(() {
          _items.addAll(
            result.items.map(
              (e) => UserListItem(
                userCode: e.userCode,
                name: e.name,
                createdAt: e.createdAt,
                // /users/search 不回 updated_at：這裡用 created_at 填補以滿足 UI 顯示需求。
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

      if (!mounted || requestId != _listRequestId) {
        return;
      }

      setState(() {
        _items.addAll(result.items);
        _hasMore = result.canLoadMore;
        _page = _hasMore ? 2 : 1;
        _totalPages = result.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _listRequestId) {
        return;
      }
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
        if (!mounted || requestId != _listRequestId) {
          return;
        }
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

      final result = await repo.fetchUserList(page: _page, pageSize: _pageSize);

      if (!mounted || requestId != _listRequestId) {
        return;
      }

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
      if (!mounted || requestId != _listRequestId) {
        return;
      }
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

      if (!mounted) {
        return;
      }

      // 若使用者在等待期間又切換到其他項目，忽略舊結果。
      if (_selected?.userCode != item.userCode) {
        return;
      }

      setState(() {
        _preview = detail;
        _isPreviewLoading = false;
        _previewError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      if (_selected?.userCode != item.userCode) {
        return;
      }

      setState(() {
        _isPreviewLoading = false;
        _previewError = e.toString();
      });
    }
  }

  void _select(UserListItem item) {
    if (_selected?.userCode == item.userCode) {
      return;
    }

    setState(() {
      _selected = item;
      _preview = null;
      _previewError = null;
      _isPreviewLoading = false;
    });

    _loadPreview(item);
  }

  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    DashboardToast.show(
      context,
      message: '已複製 $label',
      variant: DashboardToastVariant.success,
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
  }

  Widget _buildEmptyState() {
    final colors = context.colorScheme;
    return Center(
      child: Text(
        _keyword.isEmpty ? '沒有資料' : '找不到符合的使用者',
        style: GoogleFonts.inter(color: colors.onSurfaceVariant),
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    final colors = context.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            '載入失敗',
            style: GoogleFonts.inter(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('重試')),
        ],
      ),
    );
  }

  Widget _buildListWithBehavior({required bool immediateSelect}) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    if (_items.isEmpty && !_isLoading) {
      if (_error != null) {
        return _buildErrorState(() {
          _prepareSearchAndShowLoading(_keyword);
          _fetchFirstPageForCurrentQuery();
        });
      }
      return _buildEmptyState();
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(0),
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

        return InkWell(
          onTap: () => immediateSelect
              ? context.navigator.pop(item)
              : _select(item),
          // 手機不適合雙擊：桌面/大螢幕維持原互動
          onDoubleTap: immediateSelect
              ? null
              : () => context.navigator.pop(item),
          hoverColor: colors.onSurface.withValues(alpha: 0.05),
          child: Container(
            color: selected ? colors.primary.withValues(alpha: isDark ? 0.12 : 0.06) : null,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.surfaceContainerHigh,
                  child: Text(
                    item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                    style: TextStyle(color: colors.onSurface),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.userCode,
                        style: GoogleFonts.inter(fontSize: 12, color: colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatDate(item.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right,
                  size: 16,
                  color: selected
                      ? DashboardAccentColors.of(context).success
                      : colors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    final selected = _selected;
    final colors = context.colorScheme;

    if (selected == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_outlined, color: colors.onSurfaceVariant.withValues(alpha: 0.5), size: 32),
              const SizedBox(height: 12),
              Text(
                '點選左側使用者以預覽',
                style: GoogleFonts.inter(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '提示：單擊預覽、雙擊直接選擇',
                style: GoogleFonts.inter(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final body = () {
      if (_isPreviewLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (_previewError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colors.error,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  '預覽載入失敗',
                  style: GoogleFonts.inter(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _previewError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: colors.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _loadPreview(selected),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重試'),
                ),
              ],
            ),
          ),
        );
      }

      final preview = _preview;
      if (preview == null) {
        return const SizedBox.shrink();
      }

      final user = preview.user;
      final sessions = preview.sessions;
      final topSessions = sessions.take(5).toList(growable: false);

      final chips = <Widget>[];
      if ((user.sex ?? '').trim().isNotEmpty) {
        chips.add(Chip(label: Text('性別：${user.sex}')));
      }
      if (user.ageYears != null) {
        chips.add(Chip(label: Text('年齡：${user.ageYears}')));
      }
      if (user.assessmentDate != null) {
        chips.add(
          Chip(
            label: Text(
              '收案：${DateFormat('yyyy-MM-dd').format(user.assessmentDate!)}',
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.surfaceContainerHigh,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(color: colors.onSurface),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.userCode,
                              style: GoogleFonts.inter(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppTooltip(
                            message: '複製 user_code',
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  _copyToClipboard('user_code', user.userCode),
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (chips.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: chips)
            else
              Text(
                '（此使用者尚未填寫更多基本資料）',
                style: GoogleFonts.inter(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            const SizedBox(height: 14),
            Text(
              'Sessions / Bag（${sessions.length}）',
              style: GoogleFonts.inter(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (topSessions.isEmpty)
              Text(
                '尚未綁定任何 session(bag)',
                style: GoogleFonts.inter(color: colors.onSurfaceVariant, fontSize: 12),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final desired = maxWidth >= 640
                      ? (maxWidth - 12) / 2
                      : maxWidth;
                  final itemWidth = desired.clamp(220.0, maxWidth).toDouble();
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final s in topSessions)
                        SizedBox(
                          width: itemWidth,
                          child: SessionGridCard.fromUserSession(
                            item: s,
                            onTap: null, // 預覽時不觸發動作，僅展示
                          ),
                        ),
                      if (sessions.length > topSessions.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '… 其餘 ${sessions.length - topSessions.length} 筆略',
                            style: GoogleFonts.inter(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 8),
            Text(
              '建立：${_formatDate(user.createdAt)}   更新：${_formatDate(user.updatedAt)}',
              style: GoogleFonts.inter(
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }();

    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: body)),
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected.name,
                  style: GoogleFonts.inter(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.navigator.pop(selected),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('選擇'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final showPagingInfo = _items.isNotEmpty && _totalPages > 0;
    final isCompactScreen = context.isMobile;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            color: colors.onSurface,
            size: 24,
          ),
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
          // 手機頂端空間有限：頁碼資訊保留在下方分頁列即可
          if (showPagingInfo && !isCompactScreen)
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.onSurface,
                    ),
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

    return DashboardDialogShell(
      constraints: isCompactScreen
          ? const BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity)
          : const BoxConstraints(maxWidth: 1180, maxHeight: 840),
      insetPadding: isCompactScreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      header: header,
      body: LayoutBuilder(
        builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final useSidePreview = constraints.maxWidth >= 860;

            final searchBar = Padding(
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

            final listPane = Column(
              children: [
                Expanded(child: _buildListWithBehavior(immediateSelect: isCompact)),
                _buildPaginationFooter(),
                if (!isCompact)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
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

            final previewPane = _buildPreview();

            return Column(
              children: [
                searchBar,
                Divider(height: 1, color: colors.outlineVariant),
                Expanded(
                  child: isCompact
                      // 手機：只顯示列表，避免「預覽區」佔掉半個畫面造成怪異空白。
                      ? listPane
                      : useSidePreview
                          ? Row(
                              children: [
                                SizedBox(width: 460, child: listPane),
                                VerticalDivider(
                                  width: 1,
                                  color: colors.outlineVariant,
                                ),
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
}

// _SessionPreviewTile 類別已替換為 SessionGridCard，故移除舊實作。
