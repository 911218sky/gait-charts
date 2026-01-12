import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/admin/domain/validators/admin_username_validator.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_management_provider.dart';

/// 修改帳號對話框。
///
/// 讓管理員修改自己的 username。
/// 更新後會立即影響登入顯示與管理員清單。
class UpdateUsernameDialog extends ConsumerStatefulWidget {
  const UpdateUsernameDialog({
    required this.initialUsername,
    super.key,
  });

  final String initialUsername;

  /// 顯示修改帳號對話框。
  ///
  /// 若使用者尚未登入會顯示錯誤訊息並返回。
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(adminAuthProvider).asData?.value;
    if (auth == null) {
      DashboardToast.show(
        context,
        message: '尚未登入，請重新登入',
        variant: DashboardToastVariant.danger,
      );
      return;
    }

    return showDialog<void>(
      context: context,
      builder: (context) => UpdateUsernameDialog(
        initialUsername: auth.admin.username,
      ),
    );
  }

  @override
  ConsumerState<UpdateUsernameDialog> createState() =>
      _UpdateUsernameDialogState();
}

class _UpdateUsernameDialogState extends ConsumerState<UpdateUsernameDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(
    String message, {
    DashboardToastVariant variant = DashboardToastVariant.info,
  }) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final next = _controller.text.trim();

    // 沒有變更就直接關閉
    if (next == widget.initialUsername) {
      _toast('帳號未變更', variant: DashboardToastVariant.info);
      Navigator.of(context).pop();
      return;
    }

    if (!isValidAdminUsername(next)) {
      setState(() {
        _errorText = '帳號需 3~64 字且僅限英數與 . _ -';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    try {
      await ref.read(adminAuthProvider.notifier).updateMeUsername(next);
      if (!mounted) return;
      _toast('帳號已更新', variant: DashboardToastVariant.success);
      await ref.read(adminManagementProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      _toast('更新失敗：$error', variant: DashboardToastVariant.danger);
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _controller,
              enabled: !_isSaving,
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
                  Icons.account_circle_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) => _submit(),
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
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: Text(_isSaving ? '更新中...' : '儲存'),
            ),
          ],
        ),
      ),
      expandBody: false,
    );
  }
}
