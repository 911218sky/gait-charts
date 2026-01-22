import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_management_provider.dart';
import 'package:intl/intl.dart';

/// 邀請碼產生與顯示區塊。
///
/// 讓管理員可以產生新的邀請碼，並顯示最近產生的邀請碼資訊。
class AdminInviteCodeSection extends ConsumerStatefulWidget {
  const AdminInviteCodeSection({super.key});

  @override
  ConsumerState<AdminInviteCodeSection> createState() =>
      _AdminInviteCodeSectionState();
}

class _AdminInviteCodeSectionState
    extends ConsumerState<AdminInviteCodeSection> {
  // 預設 24 小時，最短 6 小時避免太快過期
  int _expiresHours = 24;

  String _formatDateTime(DateTime value) {
    // 後端回傳 UTC，轉成本地時間方便閱讀
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final state = ref.watch(adminManagementProvider);
    final isMobile = context.isMobile;

    final headerIcon = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person_add_alt_1, color: colors.onPrimaryContainer),
    );

    final headerTitle = Text(
      '產生邀請碼',
      style: context.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    final expiresSelector = SizedBox(
      width: 100,
      child: AppSelect<int>(
        value: _expiresHours,
        items: const [6, 12, 24, 48, 72, 168],
        itemLabelBuilder: (hours) =>
            hours >= 24 * 7 ? '${hours ~/ 24} 天' : '$hours 小時',
        enabled: !state.isLoading,
        onChanged: (value) => setState(() => _expiresHours = value),
      ),
    );

    final generateButton = FilledButton.icon(
      onPressed: state.isLoading ? null : _createInvitation,
      icon: const Icon(Icons.qr_code_2),
      label: const Text('產生'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 44),
      ),
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - 響應式
            if (isMobile) ...[
              Row(
                children: [
                  headerIcon,
                  const SizedBox(width: 12),
                  headerTitle,
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  expiresSelector,
                  const SizedBox(width: 12),
                  Expanded(child: generateButton),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  headerIcon,
                  const SizedBox(width: 12),
                  headerTitle,
                  const Spacer(),
                  expiresSelector,
                  const SizedBox(width: 12),
                  generateButton,
                ],
              ),
            ],
            const SizedBox(height: 16),
            _InvitationDisplay(
              invitation: state.asData?.value.latestInvitation,
              isMobile: isMobile,
              formatDateTime: _formatDateTime,
              onCopy: () => _toast('已複製邀請碼'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 邀請碼顯示區塊（內部元件）。
class _InvitationDisplay extends StatelessWidget {
  const _InvitationDisplay({
    required this.invitation,
    required this.isMobile,
    required this.formatDateTime,
    required this.onCopy,
  });

  final InvitationCode? invitation;
  final bool isMobile;
  final String Function(DateTime) formatDateTime;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    if (invitation == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border:
              Border.all(color: colors.outlineVariant, style: BorderStyle.none),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            isMobile ? '點擊「產生」建立新的邀請碼。' : '暫無邀請碼，點擊右上角「產生」建立新的邀請碼。',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invitation!.code,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: isMobile ? 18 : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: invitation!.code));
                  onCopy();
                },
                tooltip: '複製邀請碼',
                icon: const Icon(Icons.content_copy, size: 20),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '過期時間：${formatDateTime(invitation!.expiresAt)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
