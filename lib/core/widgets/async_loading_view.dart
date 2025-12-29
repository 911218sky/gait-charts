import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 統一呈現非同步載入狀態的圓形指示器與提示文字。
class AsyncLoadingView extends StatelessWidget {
  const AsyncLoadingView({super.key, this.label});

  final String? label; // 載入提示文字

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 56,
            width: 56,
            child: CircularProgressIndicator(),
          ),
          // 如果有提示文字則顯示
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(
              label!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
