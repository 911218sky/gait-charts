import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// 使用者瀏覽器空狀態視圖。
class UserBrowserEmptyState extends StatelessWidget {
  const UserBrowserEmptyState({required this.hasKeyword, super.key});

  final bool hasKeyword;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Text(
        hasKeyword ? '找不到符合的使用者' : '沒有資料',
        style: GoogleFonts.inter(color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// 使用者瀏覽器錯誤狀態視圖。
class UserBrowserErrorState extends StatelessWidget {
  const UserBrowserErrorState({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            '載入失敗',
            style: GoogleFonts.inter(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('重試')),
        ],
      ),
    );
  }
}
