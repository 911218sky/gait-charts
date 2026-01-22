import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 非同步載入失敗時的錯誤提示與重試按鈕。
///
/// 設計風格：Vercel 風格的極簡深色設計，使用微妙的漸層與動畫效果。
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    required this.error,
    super.key,
    this.onRetry,
    this.compact = false,
  });

  /// 錯誤物件
  final Object error;

  /// 重試回呼
  final VoidCallback? onRetry;

  /// 精簡模式，適用於小區塊
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final accentColors = DashboardAccentColors.of(context);

    // 從錯誤中提取可讀訊息
    final errorMessage = error.toString().replaceAll('Exception:', '').trim();

    if (compact) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: accentColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '載入失敗',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('重試'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 錯誤圖示區塊
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 28,
                  color: accentColors.danger,
                ),
              ),
              const SizedBox(height: 20),
              // 標題
              Text(
                '無法載入資料',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // 錯誤訊息
              Text(
                errorMessage.isEmpty ? '發生未知錯誤，請稍後再試' : errorMessage,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
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
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('重新載入'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
