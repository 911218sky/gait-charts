import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';

/// 解除使用者與 session(bag) 的綁定確認對話框。
class UnlinkUserSessionDialog extends StatelessWidget {
  const UnlinkUserSessionDialog({
    required this.userName,
    required this.sessionName,
    required this.bagPath,
    super.key,
  });

  final String userName;
  final String sessionName;
  final String bagPath;

  static Future<bool?> show(
    BuildContext context, {
    required String userName,
    required String sessionName,
    required String bagPath,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => UnlinkUserSessionDialog(
        userName: userName,
        sessionName: sessionName,
        bagPath: bagPath,
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
        title: '解除綁定',
        subtitle: '確定要解除此 session(bag) 與使用者的連結嗎？',
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
                  const SizedBox(height: 10),
                  Text(
                    sessionName,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bagPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '解除綁定後，此 session 仍會保留在系統中（不會刪除檔案或 DB 紀錄）。',
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
              child: const Text('確認解除'),
            ),
          ],
        ),
      ),
    );
  }
}


