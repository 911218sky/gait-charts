import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';

/// 刪除 Session 的確認對話框。
///
/// 設計重點：
/// - 只做一次「是否確認刪除」的確認
/// - 實際刪除策略由呼叫端決定（例如預設刪 DB + 檔案）
/// - 使用類 Vercel 的深色風格
class DeleteSessionDialog extends StatelessWidget {
  const DeleteSessionDialog({required this.sessionName, super.key});

  final String sessionName;

  static Future<bool?> show(
    BuildContext context, {
    required String sessionName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteSessionDialog(sessionName: sessionName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 460),
      expandBody: false,
      header: DashboardDialogHeader(
        title: '刪除 Session',
        subtitle: '確定要刪除以下 session 嗎？此動作無法復原。',
        trailing: IconButton(
          tooltip: '關閉',
          onPressed: () => context.navigator.pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: SelectableText(
            sessionName,
            style: context.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
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
              child: const Text('確認刪除'),
            ),
          ],
        ),
      ),
    );
  }
}
