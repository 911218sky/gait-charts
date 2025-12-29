import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

/// 處理進度摘要
class ExtractionProcessingSummary extends StatelessWidget {
  const ExtractionProcessingSummary({required this.state, super.key});

  final BatchExtractionState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accents = context.extension<DashboardAccentColors>();
    final textTheme = context.textTheme;

    final summaryTextStyle = textTheme.bodyMedium?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.82),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: context.scaffoldBackgroundColor,
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          if (state.isProcessing) ...[
            const RepaintBoundary(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '正在處理... (${state.runningCount} 個執行中，${state.completedCount}/${state.items.length} 已完成)',
                style: summaryTextStyle,
              ),
            ),
          ] else ...[
            Icon(
              state.failedCount > 0 ? Icons.warning_amber : Icons.check_circle,
              size: 20,
              color: state.failedCount > 0
                  ? accents?.warning ?? Colors.orange
                  : accents?.success ?? Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '處理完成：${state.successCount} 成功，${state.failedCount} 失敗',
                style: summaryTextStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 資料提取時顯示的 loading 動畫
class ExtractionLoadingView extends StatefulWidget {
  const ExtractionLoadingView({super.key});

  @override
  State<ExtractionLoadingView> createState() => _ExtractionLoadingViewState();
}

class _ExtractionLoadingViewState extends State<ExtractionLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final primary = colors.primary;
    final textTheme = context.textTheme;
    return Card(
      child: Container(
        height: 500,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: (1 - _controller.value) * 0.28),
                      width: 2 + _controller.value * 4,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 20 * _controller.value,
                            spreadRadius: 5 * _controller.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              '正在處理您的資料...',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '這可能需要幾分鐘，請勿關閉視窗。',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing...',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.9),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
