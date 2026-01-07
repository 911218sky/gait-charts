import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/sessions/session_list_state.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/sessions/batch_delete_sessions_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';
import 'package:intl/intl.dart';

/// Session 管理頁：支援多選並批量刪除 sessions。
class DashboardSessionManagementView extends ConsumerStatefulWidget {
  const DashboardSessionManagementView({super.key});

  @override
  ConsumerState<DashboardSessionManagementView> createState() =>
      _DashboardSessionManagementViewState();
}

class _DashboardSessionManagementViewState
    extends ConsumerState<DashboardSessionManagementView> {
  bool _requested = false;
  final Set<String> _selected = <String>{};
  bool _isBatchDeleting = false;

  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionListProvider.notifier).fetchFirstPage(force: true);
    });
  }

  void _toggleSelected(String sessionName, bool selected) {
    final name = sessionName.trim();
    if (name.isEmpty) return;
    setState(() {
      if (selected) {
        _selected.add(name);
      } else {
        _selected.remove(name);
      }
    });
  }

  void _selectAllOnPage(List<RealsenseSessionItem> items) {
    setState(() {
      for (final item in items) {
        final name = item.sessionName.trim();
        if (name.isNotEmpty) {
          _selected.add(name);
        }
      }
    });
  }

  void _clearSelection() {
    setState(_selected.clear);
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  Future<void> _batchDelete() async {
    if (_isBatchDeleting || _selected.isEmpty) return;

    final sessionNames = _selected.toList(growable: false)..sort();
    final confirmed = await BatchDeleteSessionsDialog.confirm(
      context,
      sessionNames: sessionNames,
    );
    if (!mounted || confirmed != true) return;

    setState(() => _isBatchDeleting = true);
    try {
      final response = await _repo.deleteRealsenseSessionsBatch(
        request: DeleteSessionsBatchRequest(sessionNames: sessionNames),
      );
      if (!mounted) return;

      final failed = response.failed.toSet();
      final deletedNames = sessionNames
          .where((e) => !failed.contains(e))
          .toSet();

      // 就地更新列表（避免重載造成閃爍），同時清除選取狀態。
      ref.read(sessionListProvider.notifier).removeSessions(deletedNames);
      setState(() {
        _selected.removeWhere(deletedNames.contains);
      });

      await BatchDeleteSessionsDialog.showResult(context, response: response);
    } catch (e) {
      if (!mounted) return;
      DashboardToast.show(
        context,
        message: '批量刪除失敗：$e',
        variant: DashboardToastVariant.danger,
      );
    } finally {
      if (mounted) setState(() => _isBatchDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final state = ref.watch(sessionListProvider);
    final notifier = ref.read(sessionListProvider.notifier);

    final items = state.items;
    final canDelete = _selected.isNotEmpty && !_isBatchDeleting;

    return ListView(
      padding: dashboardPagePadding(context),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session 管理',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '多選 sessions 後可一次刪除（DB / npy / video / bag）。',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: state.isLoading || _isBatchDeleting
                          ? null
                          : () => notifier.fetchFirstPage(force: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新整理'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: canDelete ? _batchDelete : null,
                      icon: _isBatchDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              // 使用 determinate indicator，避免 widget_test 的 pumpAndSettle 因無限動畫而 timeout。
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: 0.25,
                              ),
                            )
                          : const Icon(Icons.delete_outline),
                      label: Text(
                        _isBatchDeleting ? '刪除中…' : '批量刪除（${_selected.length}）',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardAccentColors.of(
                          context,
                        ).danger,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: items.isEmpty || _isBatchDeleting
                          ? null
                          : () => _selectAllOnPage(items),
                      icon: const Icon(Icons.select_all),
                      label: const Text('全選（本頁）'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _selected.isEmpty || _isBatchDeleting
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
                        '已選取 ${_selected.length} / 本頁 ${items.length}',
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    if (state.totalPages > 0)
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
                          '第 ${state.page <= 0 ? 1 : state.page} / 共 ${state.totalPages} 頁',
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              if (state.isInitialLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  // 使用 determinate indicator，避免 widget_test 的 pumpAndSettle 因無限動畫而 timeout。
                  child: Center(child: CircularProgressIndicator(value: 0.25)),
                )
              else if (state.error != null && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: colors.error, size: 32),
                      const SizedBox(height: 10),
                      Text(
                        '載入失敗：${state.error}',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => notifier.fetchFirstPage(force: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('重試'),
                      ),
                    ],
                  ),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '沒有 sessions',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outlineVariant),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = item.sessionName;
                    final checked = _selected.contains(name);
                    return ListTile(
                      leading: Checkbox(
                        value: checked,
                        onChanged: _isBatchDeleting
                            ? null
                            : (v) => _toggleSelected(name, v ?? false),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      subtitle: Text(
                        '${item.bagFilename}  ·  ${_formatDateTime(item.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.hasVideo)
                            Icon(
                              Icons.videocam,
                              size: 18,
                              color: colors.primary,
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ],
                      ),
                      onTap: _isBatchDeleting
                          ? null
                          : () => _toggleSelected(name, !checked),
                    );
                  },
                ),
              if (state.totalPages > 0) ...[
                Divider(height: 1, color: colors.outlineVariant),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.isLoading || state.page <= 1
                            ? null
                            : () => notifier.goToPage(state.page - 1),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('上一頁'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: state.isLoading || !state.canLoadMore
                            ? null
                            : () => notifier.goToPage(state.page + 1),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('下一頁'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
