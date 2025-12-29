import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';

/// 一次解除某個使用者名下所有 sessions(bag) 的綁定確認對話框。
class UnlinkAllUserSessionsDialog extends StatelessWidget {
  const UnlinkAllUserSessionsDialog({
    required this.userName,
    required this.userCode,
    required this.sessionCount,
    super.key,
  });

  final String userName;
  final String userCode;
  final int sessionCount;

  static Future<bool?> show(
    BuildContext context, {
    required String userName,
    required String userCode,
    required int sessionCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => UnlinkAllUserSessionsDialog(
        userName: userName,
        userCode: userCode,
        sessionCount: sessionCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 560),
      expandBody: false,
      header: DashboardDialogHeader(
        title: '全部解除綁定',
        subtitle: '確定要解除此使用者名下所有 sessions(bag) 的連結嗎？',
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    userCode,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '將解除 $sessionCount 筆 sessions 的綁定',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '解除綁定後 sessions 仍會保留在系統中（不會刪除檔案或 DB 紀錄）。',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.navigator.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: accent.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('確認全部解除'),
            ),
          ],
        ),
      ),
    );
  }
}


