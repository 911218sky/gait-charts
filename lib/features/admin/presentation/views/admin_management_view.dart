import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/domain/validators/admin_username_validator.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_management_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';
import 'package:intl/intl.dart';

/// 管理員清單與邀請碼管理。
class AdminManagementView extends ConsumerStatefulWidget {
  const AdminManagementView({super.key});

  @override
  ConsumerState<AdminManagementView> createState() =>
      _AdminManagementViewState();
}

class _AdminManagementViewState extends ConsumerState<AdminManagementView> {
  int _expiresHours = 24;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  void _toast(
    String message, {
    DashboardToastVariant variant = DashboardToastVariant.info,
  }) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  Future<void> _createInvitation() async {
    final notifier = ref.read(adminManagementProvider.notifier);
    try {
      final invitation =
          await notifier.createInvitation(expiresInHours: _expiresHours);
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: invitation.code));
      _toast(
        '已產生邀請碼並複製：${invitation.code}',
        variant: DashboardToastVariant.success,
      );
    } catch (error) {
      if (!mounted) return;
      _toast('產生邀請碼失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _deleteAdmin(AdminListItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.colorScheme;
        return DashboardDialogShell(
          header: const DashboardDialogHeader(title: '刪除管理員'),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '確認刪除管理員：${item.username}\n此動作不可復原，並會移除該管理員的 sessions。',
              style: context.textTheme.bodyLarge,
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.navigator.pop(false),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                  onPressed: () => context.navigator.pop(true),
                  child: const Text('確認刪除'),
                ),
              ],
            ),
          ),
          expandBody: false,
        );
      },
    );
    if (result != true) {
      return;
    }
    final notifier = ref.read(adminManagementProvider.notifier);
    try {
      await notifier.deleteAdmin(item.adminCode);
      if (!mounted) return;
      _toast('已刪除 ${item.username}', variant: DashboardToastVariant.success);
    } catch (error) {
      if (!mounted) return;
      _toast('刪除失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final auth = ref.watch(adminAuthProvider).asData?.value;
    final state = ref.watch(adminManagementProvider);
    final notifier = ref.read(adminManagementProvider.notifier);

    return Padding(
      padding: dashboardPagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '人員管理',
                    style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '檢視、刪除管理員與產生邀請碼。',
                    style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: state.isLoading ? null : notifier.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('重新整理'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showChangePasswordDialog(context),
                icon: const Icon(Icons.password),
                label: const Text('變更密碼'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    auth == null ? null : () => _showUpdateUsernameDialog(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('修改帳號'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  await ref.read(adminAuthProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('登出'),
              ),
            ],
          ),
          if (auth != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle,
                      size: 20, color: colors.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    '目前登入：${auth.admin.username}',
                    style: context.textTheme.labelLarge?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${auth.admin.adminCode})',
                    style: context.textTheme.labelMedium?.copyWith(
                          color: colors.onSecondaryContainer.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Invite Code Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.outlineVariant),
            ),
            elevation: 0,
            color: colors.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_add_alt_1,
                            color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '產生邀請碼',
                        style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        child: AppSelect<int>(
                          value: _expiresHours,
                          items: const [6, 12, 24, 48, 72, 168],
                          itemLabelBuilder: (hours) =>
                              hours >= 24 * 7 ? '${hours ~/ 24} 天' : '$hours 小時',
                          enabled: !state.isLoading,
                          onChanged: (value) =>
                              setState(() => _expiresHours = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: state.isLoading ? null : _createInvitation,
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('產生'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final invitation = state.asData?.value.latestInvitation;
                      if (invitation == null) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: colors.outlineVariant,
                                style: BorderStyle.none),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '暫無邀請碼，點擊右上角「產生」建立新的邀請碼。',
                              style: context.textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      invitation.code,
                                      style: context.textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: invitation.code),
                                        );
                                        if (mounted) {
                                          _toast('已複製邀請碼');
                                        }
                                      },
                                      tooltip: '複製邀請碼',
                                      icon: const Icon(Icons.content_copy,
                                          size: 20),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: 16,
                                        color: colors.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      '過期時間：${_formatDateTime(invitation.expiresAt)}',
                                      style: context.textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Admin List
          Expanded(
            child: AsyncRequestView<AdminManagementState>(
              requestId: 'admins/list',
              value: state,
              onRetry: notifier.refresh,
              loadingLabel: '載入管理員清單...',
              dataBuilder: (context, data) {
                final items = data.list.items;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: colors.outline),
                        const SizedBox(height: 16),
                        Text(
                          '目前沒有其他管理員',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisExtent: 180, // 固定高度類似名片
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isMe = item.adminCode == auth?.admin.adminCode;
                          final canDelete = item.canDelete && !isMe;

                          return _AdminCard(
                            item: item,
                            isMe: isMe,
                            canDelete: canDelete,
                            onDelete: () => _deleteAdmin(item),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DashboardPaginationFooter(
                      currentPage: data.list.page,
                      totalPages: data.list.totalPages,
                      onSelectPage: (page) {
                        notifier.refresh(page: page);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool obscureOld = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setState) {
            final colors = context.colorScheme;

            Widget buildPasswordField({
              required TextEditingController controller,
              required String label,
              required bool obscureText,
              required VoidCallback onToggle,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    obscureText: obscureText,
                    style: TextStyle(color: colors.onSurface, fontSize: 14),
                    cursorColor: colors.primary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.isDark
                          ? const Color(0xFF111111)
                          : colors.surface,
                      hoverColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: colors.primary),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        onPressed: onToggle,
                      ),
                    ),
                  ),
                ],
              );
            }

            return DashboardDialogShell(
              header: const DashboardDialogHeader(
                title: '變更密碼',
                subtitle: '為了您的帳號安全，建議定期更換密碼。',
              ),
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildPasswordField(
                      controller: _oldPasswordController,
                      label: '舊密碼',
                      obscureText: obscureOld,
                      onToggle: () => setState(() => obscureOld = !obscureOld),
                    ),
                    const SizedBox(height: 16),
                    buildPasswordField(
                      controller: _newPasswordController,
                      label: '新密碼（8~128 字）',
                      obscureText: obscureNew,
                      onToggle: () => setState(() => obscureNew = !obscureNew),
                    ),
                    const SizedBox(height: 16),
                    buildPasswordField(
                      controller: _confirmPasswordController,
                      label: '確認新密碼',
                      obscureText: obscureConfirm,
                      onToggle: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ],
                ),
              ),
              footer: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.navigator.pop(false),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => context.navigator.pop(true),
                      child: const Text('送出'),
                    ),
                  ],
                ),
              ),
              expandBody: false,
            );
          },
        );
      },
    );

    if (result != true || !mounted) {
      return;
    }

    final oldPwd = _oldPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPwd != confirm) {
      _toast('新密碼與確認不一致', variant: DashboardToastVariant.danger);
      return;
    }
    if (newPwd.length < 8 || newPwd.length > 128) {
      _toast('新密碼需 8~128 字', variant: DashboardToastVariant.danger);
      return;
    }

    try {
      final session = await ref.read(adminAuthProvider.notifier).changePassword(
            oldPassword: oldPwd,
            newPassword: newPwd,
          );
      if (!mounted) return;
      if (session != null) {
        _toast('密碼已更新並重新登入', variant: DashboardToastVariant.success);
        await ref.read(adminManagementProvider.notifier).refresh();
      }
    } catch (error) {
      if (!mounted) return;
      _toast('變更失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _showUpdateUsernameDialog(BuildContext context) async {
    final auth = ref.read(adminAuthProvider).asData?.value;
    if (auth == null) {
      _toast('尚未登入，請重新登入', variant: DashboardToastVariant.danger);
      return;
    }

    final initialUsername = auth.admin.username;
    final controller = TextEditingController(text: initialUsername);

    String? errorText;
    bool isSaving = false;

    Future<void> onSubmit(StateSetter setState) async {
      if (isSaving) return;
      final next = controller.text.trim();

      if (next == initialUsername) {
        if (mounted) {
          _toast('帳號未變更', variant: DashboardToastVariant.info);
        }
        if (context.mounted) {
          context.navigator.pop();
        }
        return;
      }

      if (!isValidAdminUsername(next)) {
        setState(() {
          errorText = '帳號需 3~64 字且僅限英數與 . _ -';
        });
        return;
      }

      setState(() {
        errorText = null;
        isSaving = true;
      });

      try {
        await ref.read(adminAuthProvider.notifier).updateMeUsername(next);
        if (!mounted) return;
        _toast('帳號已更新', variant: DashboardToastVariant.success);
        await ref.read(adminManagementProvider.notifier).refresh();
        if (context.mounted) {
          context.navigator.pop();
        }
      } catch (error) {
        if (!mounted) return;
        _toast('更新失敗：$error', variant: DashboardToastVariant.danger);
        setState(() => isSaving = false);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final colors = context.colorScheme;
            return DashboardDialogShell(
              header: const DashboardDialogHeader(
                title: '修改帳號',
                subtitle: '3~64 字，僅限英數與 . _ -',
              ),
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '帳號（username）',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      enabled: !isSaving,
                      style: TextStyle(color: colors.onSurface, fontSize: 14),
                      cursorColor: colors.primary,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(adminUsernameMaxLength),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9._-]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.isDark
                            ? const Color(0xFF111111)
                            : colors.surface,
                        hoverColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                        prefixIcon: Icon(
                          Icons.account_circle_outlined,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        errorText: errorText,
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setState(() => errorText = null);
                        }
                      },
                      onSubmitted: (_) => onSubmit(setState),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '更新後會立即影響登入顯示與管理員清單。',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              footer: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          isSaving ? null : () => context.navigator.pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: isSaving ? null : () => onSubmit(setState),
                      child: Text(isSaving ? '更新中...' : '儲存'),
                    ),
                  ],
                ),
              ),
              expandBody: false,
            );
          },
        );
      },
    );

    controller.dispose();
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.item,
    required this.isMe,
    required this.canDelete,
    required this.onDelete,
  });

  final AdminListItem item;
  final bool isMe;
  final bool canDelete;
  final VoidCallback onDelete;

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: colors.primary,
                  size: 28,
                ),
              ),
              const Spacer(),
              if (isMe)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'YOU',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: colors.error),
                  tooltip: '刪除',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else if (!isMe)
                Icon(Icons.lock_outline, size: 20, color: colors.outline),
            ],
          ),
          const Spacer(),
          Text(
            item.username,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.adminCode,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(item.createdAt),
                style:
                    textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (item.invitedByCode != null) ...[
                const Spacer(),
                Icon(Icons.link, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Invited',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
