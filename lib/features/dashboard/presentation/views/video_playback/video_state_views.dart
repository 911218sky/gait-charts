import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 影片播放頁面的空狀態顯示。
///
/// 當使用者尚未選擇任何 session 時顯示。
class VideoEmptyState extends StatelessWidget {
  const VideoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '選擇一個 Session 來播放影片',
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '輸入 session 名稱或點擊「瀏覽 Sessions」選擇',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 影片載入中狀態顯示。
class VideoLoadingState extends StatelessWidget {
  const VideoLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '檢查影片可用性...',
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 影片錯誤狀態顯示。
///
/// 用於顯示各種錯誤情況，如 session 不存在、影片遺失等。
class VideoErrorState extends StatelessWidget {
  const VideoErrorState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: colors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
