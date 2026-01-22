import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/initial_avatar.dart';
import 'package:google_fonts/google_fonts.dart';

/// 刪除單一 Cohort Benchmark 的確認對話框。
class DeleteCohortBenchmarkDialog extends StatelessWidget {
  const DeleteCohortBenchmarkDialog({required this.cohortName, super.key});

  final String cohortName;

  static Future<bool?> show(
    BuildContext context, {
    required String cohortName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteCohortBenchmarkDialog(cohortName: cohortName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    return Dialog(
      backgroundColor: context.surfaceDeepest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 警告圖示
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 32,
                color: accent.danger,
              ),
            ),
            const SizedBox(height: 24),
            // 標題
            Text(
              '刪除族群基準值',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            // 說明
            Text(
              '確定要刪除以下族群的基準值嗎？此動作無法復原。',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Cohort 名稱卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  InitialAvatar(
                    text: cohortName,
                    size: 44,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      cohortName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // 按鈕
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('確認刪除'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
