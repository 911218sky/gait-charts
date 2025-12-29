import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 顯示非同步載入失敗時的友善錯誤提示與重試行為。
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    required this.error,
    super.key,
    this.onRetry,
    this.compact = false,
  });

  final Object error; // 錯誤物件
  final VoidCallback? onRetry; // 重試回呼函式
  final bool compact; // 是否為精簡模式 (適用於小區塊)

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final accentColors = DashboardAccentColors.of(context);

    // 嘗試從錯誤中提取可讀訊息，若是一般 Exception 則取 toString
    // 這裡可以根據專案實際 Exception 類型做更細緻的 parsing
    final errorMessage = error.toString().replaceAll('Exception:', '').trim();

    if (compact) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: accentColors.danger, size: 24),
              const SizedBox(height: 8),
              Text(
                '載入失敗',
                style: textTheme.labelMedium?.copyWith(
                  color: accentColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: colors.onSurface,
                  ),
                  tooltip: '重試',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.dividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: accentColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '資料載入遇到問題',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.onSurface,
                    foregroundColor: colors.surface,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重新嘗試'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
