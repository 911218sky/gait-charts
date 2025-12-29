import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/async_error_view.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

/// 從伺服器挑選 bag 檔案（支援多選與分頁）。
class BagPickerDialog extends ConsumerStatefulWidget {
  const BagPickerDialog({
    super.key,
    required this.maxSelection,
  });

  final int maxSelection;

  static Future<List<BagFileItem>?> show(
    BuildContext context, {
    int maxSelection = 3,
  }) {
    return showDialog<List<BagFileItem>>(
      context: context,
      builder: (_) => BagPickerDialog(maxSelection: maxSelection),
    );
  }

  @override
  ConsumerState<BagPickerDialog> createState() => _BagPickerDialogState();
}

class _BagPickerDialogState extends ConsumerState<BagPickerDialog> {
  bool _requested = false;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, BagFileItem> _selectedById = <String, BagFileItem>{};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 讓 TextField 反映目前 provider 的 query（避免 dialog reopen 時 UI/狀態不一致）。
        final q = ref.read(bagListProvider).query;
        if (_searchController.text != q) {
          _searchController.text = q;
        }
        ref.read(bagListProvider.notifier).fetchFirstPage(force: true);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(BagFileItem item) {
    final id = item.bagId;
    if (id.isEmpty) return;

    setState(() {
      if (_selectedById.containsKey(id)) {
        _selectedById.remove(id);
        return;
      }
      if (_selectedById.length >= widget.maxSelection) {
        // 超過上限不選入（避免 build 內顯示 toast/snackbar）
        return;
      }
      _selectedById[id] = item;
    });
  }

  void _confirm() {
    final selected = _selectedById.values.toList(growable: false);
    context.navigator.pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bagListProvider);
    final notifier = ref.read(bagListProvider.notifier);
    final query = state.query;

    final colors = context.colorScheme;
    final backgroundColor =
        context.isDark ? colors.surface : colors.surfaceContainer;

    final header = DashboardDialogHeader(
      title: 'Select Bag Files',
      subtitle: '從伺服器挑選要提取的 .bag（最多 ${widget.maxSelection} 個）',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '重新整理',
            onPressed: state.isLoading ? null : () => notifier.fetchFirstPage(force: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '關閉',
            onPressed: () => context.navigator.pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );

    final footer = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '已選 ${_selectedById.length}/${widget.maxSelection}',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: _selectedById.isEmpty
                ? null
                : () => setState(_selectedById.clear),
            child: const Text('清空'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _selectedById.isEmpty ? null : _confirm,
            child: const Text('確認選取'),
          ),
        ],
      ),
    );

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
      backgroundColor: backgroundColor,
      header: header,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '搜尋（檔名 / 路徑）',
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) {
                      // ignore: discarded_futures
                      notifier.setQuery(v);
                    },
                    onSubmitted: (v) {
                      // ignore: discarded_futures
                      notifier.setQuery(v, immediate: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '遞迴子資料夾',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Switch.adaptive(
                      value: state.recursive,
                      onChanged: state.isLoading
                          ? null
                          : (v) => notifier.setRecursiveAndReload(v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: _BagListBody(
              state: state,
              query: query,
              selectedIds: _selectedById.keys.toSet(),
              maxSelection: widget.maxSelection,
              onToggle: _toggleSelection,
              onRetry: () => notifier.fetchFirstPage(force: true),
            ),
          ),
          DashboardPaginationFooter(
            currentPage: state.page <= 0 ? 1 : state.page,
            totalPages: state.totalPages,
            isLoading: state.isLoading,
            onSelectPage: notifier.goToPage,
          ),
        ],
      ),
      footer: footer,
    );
  }
}

class _BagListBody extends StatelessWidget {
  const _BagListBody({
    required this.state,
    required this.query,
    required this.selectedIds,
    required this.maxSelection,
    required this.onToggle,
    required this.onRetry,
  });

  final BagListState state;
  final String query;
  final Set<String> selectedIds;
  final int maxSelection;
  final ValueChanged<BagFileItem> onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return AsyncErrorView(error: state.error!, onRetry: onRetry);
    }

    final items = state.items;
    if (items.isEmpty) {
      return Center(
        child: Text(
          query.trim().isEmpty ? '目前沒有找到任何 bag 檔案' : '沒有符合搜尋條件的 bag',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: context.colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = selectedIds.contains(item.bagId);
        final canSelectMore = selected || selectedIds.length < maxSelection;
        return _BagListTile(
          item: item,
          selected: selected,
          enabled: canSelectMore,
          onTap: () => onToggle(item),
        );
      },
    );
  }
}

class _BagListTile extends StatelessWidget {
  const _BagListTile({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final BagFileItem item;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final dt = DateFormat('yyyy-MM-dd HH:mm:ss').format(item.modifiedAt);
    final size = _formatBytes(item.sizeBytes);
    final subtitle = '$dt  ·  $size';

    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: Checkbox(
        value: selected,
        onChanged: enabled ? (_) => onTap() : null,
      ),
      title: Text(
        item.name.isNotEmpty ? item.name : item.bagId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            item.bagId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final fixed = i == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$fixed ${units[i]}';
}


