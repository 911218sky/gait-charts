import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/user_autocomplete_field.dart';

/// 使用者批量刪除（呼叫後端批量刪除：POST /users/delete）。
class BatchDeleteUsersDialog extends ConsumerStatefulWidget {
  const BatchDeleteUsersDialog({super.key, this.initialQuery});

  final String? initialQuery;

  static Future<void> show(BuildContext context, {String? initialQuery}) {
    return showDialog<void>(
      context: context,
      builder: (_) => BatchDeleteUsersDialog(initialQuery: initialQuery),
    );
  }

  @override
  ConsumerState<BatchDeleteUsersDialog> createState() =>
      _BatchDeleteUsersDialogState();
}

class _BatchDeleteUsersDialogState
    extends ConsumerState<BatchDeleteUsersDialog> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  final List<UserListItem> _items = <UserListItem>[];
  final Set<String> _selectedCodes = <String>{};

  int _listRequestId = 0;
  bool _isLoading = false;
  int _page = 1;
  int _totalPages = 0;
  String? _error;
  String _keyword = '';

  bool _deleteSessions = false;
  bool _isDeleting = false;

  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _keyword = _searchController.text.trim();
    _searchController.addListener(_onSearchChanged);
    _prepareSearchAndShowLoading(_keyword);
    _fetchFirstPageForCurrentQuery();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  int get _currentPage {
    final total = _totalPages <= 0 ? 1 : _totalPages;
    return (_page - 1).clamp(1, total);
  }

  void _prepareSearchAndShowLoading(String keyword) {
    final normalized = keyword.trim();
    _listRequestId++;
    setState(() {
      _keyword = normalized;
      _items.clear();
      _selectedCodes.clear();
      _page = 1;
      _totalPages = 0;
      _isLoading = true;
      _error = null;
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

  Future<void> _fetchFirstPageForCurrentQuery() async {
    final requestId = _listRequestId;
    final keywordSnapshot = _keyword;

    try {
      if (keywordSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot,
          page: 1,
          pageSize: 20,
        );
        if (!mounted || requestId != _listRequestId) return;
        setState(() {
          _items.addAll(
            result.items
                .map(
                  (e) => UserListItem(
                    userCode: e.userCode,
                    name: e.name,
                    createdAt: e.createdAt,
                    updatedAt: e.createdAt,
                  ),
                )
                .toList(growable: false),
          );
          _totalPages = result.totalPages;
          _page = result.page + 1;
          _isLoading = false;
        });
        return;
      }

      final result = await _repo.fetchUserList(page: 1, pageSize: 20);
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _items.addAll(result.items);
        _totalPages = result.totalPages;
        _page = result.page + 1;
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

  Future<void> _goToPage(int targetPage) async {
    final total = _totalPages <= 0 ? 1 : _totalPages;
    final next = targetPage.clamp(1, total);
    if (_isLoading || _isDeleting || next == _currentPage) return;

    final requestId = ++_listRequestId;
    final keywordSnapshot = _keyword;

    setState(() {
      _items.clear();
      _selectedCodes.clear();
      _isLoading = true;
      _error = null;
    });

    try {
      if (keywordSnapshot.isNotEmpty) {
        final result = await _repo.searchUserSuggestions(
          keyword: keywordSnapshot,
          page: next,
          pageSize: 20,
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
          _page = result.page + 1;
          _isLoading = false;
        });
      } else {
        final result = await _repo.fetchUserList(page: next, pageSize: 20);
        if (!mounted || requestId != _listRequestId) return;
        setState(() {
          _items.addAll(result.items);
          _totalPages = result.totalPages;
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
  }

  void _toggleSelected(String userCode, bool selected) {
    final code = userCode.trim();
    if (code.isEmpty) return;
    setState(() {
      if (selected) {
        _selectedCodes.add(code);
      } else {
        _selectedCodes.remove(code);
      }
    });
  }

  void _selectAllOnPage() {
    setState(() {
      for (final u in _items) {
        final code = u.userCode.trim();
        if (code.isNotEmpty) _selectedCodes.add(code);
      }
    });
  }

  void _clearSelection() => setState(_selectedCodes.clear);

  Future<bool?> _confirmDelete(int count) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => DashboardDialogShell(
        constraints: const BoxConstraints(maxWidth: 520),
        expandBody: false,
        header: DashboardDialogHeader(
          title: '批量刪除使用者',
          subtitle: '即將刪除 $count 位使用者。此動作無法復原。',
          trailing: IconButton(
            tooltip: '關閉',
            onPressed: () => context.navigator.pop(),
            icon: Icon(Icons.close, color: colors.onSurfaceVariant),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _deleteSessions
                    ? '本次會連同刪除該使用者名下 sessions（delete_sessions=true）。'
                    : '本次只刪除使用者，並解除其名下 sessions 的綁定（保留 sessions）。',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '提示：將使用後端批量刪除端點一次送出（1-100 筆）。',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.navigator.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => context.navigator.pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: accent.danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('確認刪除'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _batchDelete() async {
    if (_isDeleting || _selectedCodes.isEmpty) return;
    final codes = _selectedCodes.toList(growable: false)..sort();
    final confirmed = await _confirmDelete(codes.length);
    if (!mounted || confirmed != true) return;

    setState(() => _isDeleting = true);
    DeleteUsersBatchResponse? response;
    Object? error;
    try {
      response = await _repo.deleteUsersBatch(
        request: DeleteUsersBatchRequest(
          userCodes: codes,
          deleteSessions: _deleteSessions,
        ),
      );
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (!mounted) return;
    if (response == null) {
      DashboardToast.show(
        context,
        message: '批量刪除失敗：$error',
        variant: DashboardToastVariant.danger,
      );
      return;
    }

    final failed = response.failed.toSet();
    final deleted = codes.where((e) => !failed.contains(e)).toSet();

    // 先就地移除成功刪除的使用者，避免 UI 一瞬間還顯示已刪除項目。
    setState(() {
      _items.removeWhere((e) => deleted.contains(e.userCode));
      _selectedCodes.removeWhere(deleted.contains);
    });

    final msg = failed.isEmpty
        ? '批量刪除完成：成功 ${response.deletedUsers} / ${response.totalRequested}'
        : '批量刪除完成：成功 ${response.deletedUsers} / ${response.totalRequested}，失敗 ${failed.length}';
    DashboardToast.show(
      context,
      message: msg,
      variant: failed.isEmpty
          ? DashboardToastVariant.success
          : DashboardToastVariant.warning,
    );

    if (failed.isNotEmpty) {
      final colors = context.colorScheme;
      await showDialog<void>(
        context: context,
        builder: (context) => DashboardDialogShell(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          header: DashboardDialogHeader(
            title: '部分刪除失敗',
            subtitle: '以下 user_code 刪除失敗（${failed.length}）',
            trailing: IconButton(
              tooltip: '關閉',
              onPressed: () => context.navigator.pop(),
              icon: Icon(Icons.close, color: colors.onSurfaceVariant),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant),
                color: colors.surfaceContainerLow,
              ),
              child: SelectableText(
                failed.join('\n'),
                style: context.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () => context.navigator.pop(),
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final hasPaging = _totalPages > 0;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 820),
      header: DashboardDialogHeader(
        title: '批量刪除使用者',
        subtitle: '多選後可一次刪除（逐筆呼叫後端刪除）。',
        trailing: IconButton(
          tooltip: '關閉',
          onPressed: _isDeleting ? null : () => context.navigator.pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAutocompleteField(
              controller: _searchController,
              labelText: '搜尋使用者',
              hintText: '輸入姓名關鍵字（支援自動完成）',
              helperText: '提示：可多選；刪除前請再次確認。',
              maxSuggestions: 10,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _items.isEmpty || _isDeleting
                      ? null
                      : _selectAllOnPage,
                  icon: const Icon(Icons.select_all),
                  label: const Text('全選（本頁）'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectedCodes.isEmpty || _isDeleting
                      ? null
                      : _clearSelection,
                  icon: const Icon(Icons.clear),
                  label: const Text('清除選取'),
                ),
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
                  child: Text(
                    '已選取 ${_selectedCodes.length} / 本頁 ${_items.length}',
                    style: context.textTheme.bodySmall,
                  ),
                ),
                if (hasPaging)
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
                    child: Text(
                      '第 $_currentPage / 共 $_totalPages 頁',
                      style: context.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: _isLoading && _items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : (_error != null && _items.isEmpty)
                    ? Center(
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
                              const SizedBox(height: 10),
                              Text(
                                '載入失敗：$_error',
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _isDeleting
                                    ? null
                                    : () {
                                        _prepareSearchAndShowLoading(_keyword);
                                        _fetchFirstPageForCurrentQuery();
                                      },
                                icon: const Icon(Icons.refresh),
                                label: const Text('重試'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _items.length + (_isLoading ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: colors.outlineVariant),
                        itemBuilder: (context, index) {
                          if (_isLoading && index == _items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final item = _items[index];
                          final checked = _selectedCodes.contains(
                            item.userCode,
                          );

                          return ListTile(
                            leading: Checkbox(
                              value: checked,
                              onChanged: _isDeleting
                                  ? null
                                  : (v) => _toggleSelected(
                                      item.userCode,
                                      v ?? false,
                                    ),
                            ),
                            title: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.userCode,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            onTap: _isDeleting
                                ? null
                                : () =>
                                      _toggleSelected(item.userCode, !checked),
                          );
                        },
                      ),
              ),
            ),
            if (hasPaging) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading || _isDeleting || _currentPage <= 1
                        ? null
                        : () => _goToPage(_currentPage - 1),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('上一頁'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _isLoading || _isDeleting || _currentPage >= _totalPages
                        ? null
                        : () => _goToPage(_currentPage + 1),
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('下一頁'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Switch(
                    value: _deleteSessions,
                    onChanged: _isDeleting
                        ? null
                        : (v) => setState(() => _deleteSessions = v),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _deleteSessions ? '同時刪除 sessions' : '保留 sessions（僅解除綁定）',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _isDeleting ? null : () => context.navigator.pop(),
              child: const Text('關閉'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _selectedCodes.isEmpty || _isDeleting
                  ? null
                  : _batchDelete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(
                _isDeleting ? '刪除中…' : '刪除（${_selectedCodes.length}）',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
