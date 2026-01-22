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
    final isMobile = context.isMobile;

    final items = state.items;
    final canDelete = _selected.isNotEmpty && !_isBatchDeleting;
    final accentColors = DashboardAccentColors.of(context);

    return ListView(
      padding: dashboardPagePadding(context),
      children: [
        // 頁面標題區
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session 管理',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMobile 
                    ? '批量管理 sessions'
                    : '批量管理 sessions，支援多選刪除（DB / npy / video / bag）',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // 操作工具列
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              if (!isMobile)
                Row(
                  children: [
                    // 選取操作按鈕群組
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ActionChip(
                            icon: Icons.select_all_rounded,
                            label: '全選',
                            onPressed: items.isEmpty || _isBatchDeleting
                                ? null
                                : () => _selectAllOnPage(items),
                          ),
                          _ActionChip(
                            icon: Icons.deselect_rounded,
                            label: '清除',
                            onPressed: _selected.isEmpty || _isBatchDeleting
                                ? null
                                : _clearSelection,
                          ),
                          _ActionChip(
                            icon: Icons.refresh_rounded,
                            label: '重整',
                            onPressed: state.isLoading || _isBatchDeleting
                                ? null
                                : () => notifier.fetchFirstPage(force: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 刪除按鈕
                    FilledButton.icon(
                      onPressed: canDelete ? _batchDelete : null,
                      icon: _isBatchDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        _isBatchDeleting
                            ? '刪除中…'
                            : '刪除${_selected.isEmpty ? '' : '（${_selected.length}）'}',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: canDelete
                            ? accentColors.danger
                            : colors.surfaceContainerHighest,
                        foregroundColor: canDelete
                            ? Colors.white
                            : colors.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                // 手機版：按鈕垂直排列
                Row(
                  children: [
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.select_all_rounded,
                        label: '全選',
                        onPressed: items.isEmpty || _isBatchDeleting
                            ? null
                            : () => _selectAllOnPage(items),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.deselect_rounded,
                        label: '清除',
                        onPressed: _selected.isEmpty || _isBatchDeleting
                            ? null
                            : _clearSelection,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.refresh_rounded,
                        label: '重整',
                        onPressed: state.isLoading || _isBatchDeleting
                            ? null
                            : () => notifier.fetchFirstPage(force: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canDelete ? _batchDelete : null,
                    icon: _isBatchDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      _isBatchDeleting
                          ? '刪除中…'
                          : '刪除${_selected.isEmpty ? '' : '（${_selected.length}）'}',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: canDelete
                          ? accentColors.danger
                          : colors.surfaceContainerHighest,
                      foregroundColor: canDelete
                          ? Colors.white
                          : colors.onSurfaceVariant,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // 狀態列
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusBadge(
                    icon: Icons.check_circle_outline_rounded,
                    label: '已選 ${_selected.length}',
                    isActive: _selected.isNotEmpty,
                  ),
                  _StatusBadge(
                    icon: Icons.list_rounded,
                    label: '本頁 ${items.length}',
                  ),
                  if (state.totalPages > 0)
                    _StatusBadge(
                      icon: Icons.auto_stories_rounded,
                      label: '${state.page <= 0 ? 1 : state.page} / ${state.totalPages} 頁',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Session 列表
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (state.isInitialLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null && items.isEmpty)
                _EmptyState(
                  icon: Icons.error_outline_rounded,
                  iconColor: accentColors.danger,
                  title: '載入失敗',
                  subtitle: state.error.toString(),
                  actionLabel: '重試',
                  onAction: () => notifier.fetchFirstPage(force: true),
                )
              else if (items.isEmpty)
                const _EmptyState(
                  icon: Icons.folder_off_rounded,
                  title: '沒有 Sessions',
                  subtitle: '目前沒有可管理的 session 資料',
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
                    return _SessionListTile(
                      name: name,
                      subtitle:
                          '${item.bagFilename}  ·  ${_formatDateTime(item.createdAt)}',
                      hasVideo: item.hasVideo,
                      isSelected: checked,
                      isDisabled: _isBatchDeleting,
                      onToggle: () => _toggleSelected(name, !checked),
                    );
                  },
                ),
              // 分頁控制
              if (state.totalPages > 1) ...[
                Divider(height: 1, color: colors.outlineVariant),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.outlined(
                        onPressed: state.isLoading || state.page <= 1
                            ? null
                            : () => notifier.goToPage(state.page - 1),
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${state.page <= 0 ? 1 : state.page} / ${state.totalPages}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: state.isLoading || !state.canLoadMore
                            ? null
                            : () => notifier.goToPage(state.page + 1),
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: colors.outlineVariant),
                        ),
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

/// 操作按鈕 Chip
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isEnabled ? colors.outlineVariant : colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isEnabled ? colors.onSurface : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: isEnabled ? colors.onSurface : colors.onSurfaceVariant.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 狀態標籤
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isActive
            ? colors.primary.withValues(alpha: 0.1)
            : colors.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: isActive ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空狀態顯示
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (iconColor ?? colors.onSurfaceVariant).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: iconColor ?? colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Session 列表項目
class _SessionListTile extends StatelessWidget {
  const _SessionListTile({
    required this.name,
    required this.subtitle,
    required this.hasVideo,
    required this.isSelected,
    required this.isDisabled,
    required this.onToggle,
  });

  final String name;
  final String subtitle;
  final bool hasVideo;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Material(
      color: isSelected
          ? colors.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: isDisabled ? null : (_) => onToggle(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 16),
              // 內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 標籤
              if (hasVideo) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 14,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Video',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
