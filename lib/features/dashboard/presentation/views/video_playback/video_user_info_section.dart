import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 手機版使用者資訊區塊（可收合的 ExpansionTile）。
///
/// 顯示與目前播放 session 相關的使用者基本資訊。
class MobileUserInfoSection extends StatelessWidget {
  const MobileUserInfoSection({
    required this.user,
    super.key,
  });

  final UserItem user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          user.cohort.isNotEmpty ? user.cohort.join(', ') : '未分類',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        children: [
          _InfoRow(
            icon: Icons.cake_outlined,
            label: '年齡',
            value: user.ageYears != null ? '${user.ageYears} 歲' : '未知',
          ),
          _InfoRow(
            icon: Icons.height,
            label: '身高',
            value: user.heightCm != null ? '${user.heightCm} cm' : '未知',
          ),
          _InfoRow(
            icon: Icons.monitor_weight_outlined,
            label: '體重',
            value: user.weightKg != null ? '${user.weightKg} kg' : '未知',
          ),
          if (user.notes != null && user.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.notes!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 手機版使用者資訊載入中狀態。
class MobileUserInfoLoading extends StatelessWidget {
  const MobileUserInfoLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              '載入使用者資訊...',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 資訊列（內部元件）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
