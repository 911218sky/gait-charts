import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_management_provider.dart';

/// 管理員頁面的 Header 區塊。
///
/// 包含標題、副標題和操作按鈕（重新整理、變更密碼、修改帳號、登出）。
/// 會根據螢幕大小自動調整為水平或垂直佈局。
class AdminManagementHeader extends ConsumerWidget {
  const AdminManagementHeader({
    required this.auth,
    required this.state,
    required this.onChangePassword,
    required this.onUpdateUsername,
    super.key,
  });

  final AuthSession? auth;
  final AsyncValue<AdminManagementState> state;
  final VoidCallback onChangePassword;
  final VoidCallback onUpdateUsername;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final notifier = ref.read(adminManagementProvider.notifier);
    final isMobile = context.isMobile;

    final titleSection = Column(
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
    );

    final actionButtons = [
      FilledButton.icon(
        onPressed: state.isLoading ? null : notifier.refresh,
        icon: const Icon(Icons.refresh),
        label: const Text('重新整理'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
        ),
      ),
      OutlinedButton.icon(
        onPressed: onChangePassword,
        icon: const Icon(Icons.password),
        label: const Text('變更密碼'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
        ),
      ),
      OutlinedButton.icon(
        onPressed: auth == null ? null : onUpdateUsername,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('修改帳號'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
        ),
      ),
      TextButton.icon(
        onPressed: () async {
          await ref.read(adminAuthProvider.notifier).logout();
        },
        icon: const Icon(Icons.logout),
        label: const Text('登出'),
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
        ),
      ),
    ];

    // 手機版：垂直堆疊
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actionButtons,
          ),
        ],
      );
    }

    // 桌面版：水平排列
    return Row(
      children: [
        titleSection,
        const Spacer(),
        ...actionButtons
            .expand((btn) => [btn, const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      ],
    );
  }
}
