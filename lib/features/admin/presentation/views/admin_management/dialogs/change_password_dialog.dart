import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_management_provider.dart';

/// 變更密碼對話框。
///
/// 讓管理員輸入舊密碼和新密碼來更新登入密碼。
/// 成功後會自動重新登入並刷新管理員清單。
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  /// 顯示變更密碼對話框。
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toast(
    String message, {
    DashboardToastVariant variant = DashboardToastVariant.info,
  }) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  Future<void> _submit() async {
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
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      _toast('變更失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _PasswordField(
              controller: _oldPasswordController,
              label: '舊密碼',
              obscureText: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: _newPasswordController,
              label: '新密碼（8~128 字）',
              obscureText: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: _confirmPasswordController,
              label: '確認新密碼',
              obscureText: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submit,
              child: const Text('送出'),
            ),
          ],
        ),
      ),
      expandBody: false,
    );
  }
}

/// 密碼輸入欄位（內部元件）。
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

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
            fillColor:
                context.isDark ? const Color(0xFF111111) : colors.surface,
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
}
