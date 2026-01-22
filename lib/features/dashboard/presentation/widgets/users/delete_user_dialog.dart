import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';

/// 刪除使用者的確認對話框（可選擇是否一併刪除該使用者名下 sessions）。
@immutable
class DeleteUserDialogResult {
  const DeleteUserDialogResult({required this.deleteSessions});

  /// true：連同 sessions(DB 紀錄) 一併刪除
  /// false：只解除綁定（保留 sessions）
  final bool deleteSessions;
}

class DeleteUserDialog extends StatefulWidget {
  const DeleteUserDialog({
    required this.userName,
    required this.userCode,
    super.key,
  });

  final String userName;
  final String userCode;

  static Future<DeleteUserDialogResult?> show(
    BuildContext context, {
    required String userName,
    required String userCode,
  }) {
    return showDialog<DeleteUserDialogResult>(
      context: context,
      builder: (_) => DeleteUserDialog(userName: userName, userCode: userCode),
    );
  }

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  bool _deleteSessions = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 520),
      expandBody: false,
      header: DashboardDialogHeader(
        title: '刪除使用者',
        subtitle: '確定要刪除以下使用者嗎？此動作無法復原。',
        trailing: IconButton(
          tooltip: '關閉',
          onPressed: () => context.navigator.pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.userCode,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox.adaptive(
                    value: _deleteSessions,
                    onChanged: (value) {
                      setState(() => _deleteSessions = value ?? false);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '同時刪除該使用者名下 sessions',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _deleteSessions
                              ? '會刪除 sessions 的 DB 紀錄（不只解除綁定）。'
                              : '預設只解除綁定（sessions 仍保留在系統中）。',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              onPressed: () => context.navigator.pop(
                DeleteUserDialogResult(deleteSessions: _deleteSessions),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('確認刪除'),
            ),
          ],
        ),
      ),
    );
  }
}


