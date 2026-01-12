import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_pagination_footer.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_management_provider.dart';
import 'package:gait_charts/features/admin/presentation/views/admin_management/admin_management.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';

/// 管理員清單與邀請碼管理頁面。
///
/// 提供以下功能：
/// - 檢視所有管理員清單
/// - 產生邀請碼邀請新管理員
/// - 變更密碼、修改帳號
/// - 刪除其他管理員
class AdminManagementView extends ConsumerWidget {
  const AdminManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider).asData?.value;
    final state = ref.watch(adminManagementProvider);
    final notifier = ref.read(adminManagementProvider.notifier);

    return Padding(
      padding: dashboardPagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AdminManagementHeader(
            auth: auth,
            state: state,
            onChangePassword: () => ChangePasswordDialog.show(context),
            onUpdateUsername: () => UpdateUsernameDialog.show(context, ref),
          ),

          // 目前登入者資訊
          if (auth != null) ...[
            const SizedBox(height: 12),
            _CurrentUserBadge(auth: auth),
          ],
          const SizedBox(height: 24),

          // 邀請碼區塊
          const AdminInviteCodeSection(),
          const SizedBox(height: 24),

          // 管理員清單
          Expanded(
            child: _AdminList(
              auth: auth,
              state: state,
              notifier: notifier,
            ),
          ),
        ],
      ),
    );
  }
}

/// 目前登入者標籤。
class _CurrentUserBadge extends StatelessWidget {
  const _CurrentUserBadge({required this.auth});

  final AuthSession auth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle,
            size: 20,
            color: colors.onSecondaryContainer,
          ),
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
    );
  }
}

/// 管理員清單區塊。
class _AdminList extends StatelessWidget {
  const _AdminList({
    required this.auth,
    required this.state,
    required this.notifier,
  });

  final AuthSession? auth;
  final AsyncValue<AdminManagementState> state;
  final AdminManagementNotifier notifier;

  Future<void> _deleteAdmin(BuildContext context, AdminListItem item) async {
    final colors = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return DashboardDialogShell(
          header: const DashboardDialogHeader(title: '刪除管理員'),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '確認刪除管理員：${item.username}\n此動作不可復原，並會移除該管理員的 sessions。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('確認刪除'),
                ),
              ],
            ),
          ),
          expandBody: false,
        );
      },
    );

    if (result != true || !context.mounted) return;

    try {
      await notifier.deleteAdmin(item.adminCode);
      if (!context.mounted) return;
      DashboardToast.show(
        context,
        message: '已刪除 ${item.username}',
        variant: DashboardToastVariant.success,
      );
    } catch (error) {
      if (!context.mounted) return;
      DashboardToast.show(
        context,
        message: '刪除失敗：$error',
        variant: DashboardToastVariant.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return AsyncRequestView<AdminManagementState>(
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
                Icon(Icons.people_outline, size: 64, color: colors.outline),
                const SizedBox(height: 16),
                Text(
                  '目前沒有其他管理員',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
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
                  mainAxisExtent: 180,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isMe = item.adminCode == auth?.admin.adminCode;
                  final canDelete = item.canDelete && !isMe;

                  return AdminCard(
                    item: item,
                    isMe: isMe,
                    canDelete: canDelete,
                    onDelete: () => _deleteAdmin(context, item),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            DashboardPaginationFooter(
              currentPage: data.list.page,
              totalPages: data.list.totalPages,
              onSelectPage: (page) => notifier.refresh(page: page),
            ),
          ],
        );
      },
    );
  }
}
