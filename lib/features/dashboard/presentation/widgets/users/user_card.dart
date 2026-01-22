import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 使用者基本資料卡片。
class UserCard extends StatelessWidget {
  const UserCard({
    required this.user,
    required this.isBusy,
    required this.formatDate,
    required this.formatDateTime,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    super.key,
  });

  final UserItem user;
  final bool isBusy;

  final String Function(DateTime? value) formatDate;
  final String Function(DateTime value) formatDateTime;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text('user_code：${user.userCode}'),
                            avatar: const Icon(Icons.badge_outlined, size: 18),
                          ),
                          if (user.cohort.isNotEmpty)
                            ...user.cohort.map(
                              (c) => Chip(
                                label: Text(c),
                                avatar: const Icon(
                                  Icons.groups_rounded,
                                  size: 18,
                                ),
                              ),
                            ),
                          ActionChip(
                            label: const Text('複製'),
                            avatar: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () => onCopy('user_code', user.userCode),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('編輯'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('刪除'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardAccentColors.of(context).danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _LabeledGrid(
              children: [
                _LabeledValue(
                  label: '收案日期',
                  value: formatDate(user.assessmentDate),
                  icon: Icons.event_outlined,
                ),
                _LabeledValue(
                  label: '性別',
                  value: user.sex ?? '—',
                  icon: Icons.wc_outlined,
                ),
                _LabeledValue(
                  label: '年齡(歲)',
                  value: user.ageYears?.toString() ?? '—',
                  icon: Icons.cake_outlined,
                ),
                _LabeledValue(
                  label: '身高(cm)',
                  value: user.heightCm?.toStringAsFixed(1) ?? '—',
                  icon: Icons.height_outlined,
                ),
                _LabeledValue(
                  label: '體重(kg)',
                  value: user.weightKg?.toStringAsFixed(1) ?? '—',
                  icon: Icons.monitor_weight_outlined,
                ),
                _LabeledValue(
                  label: 'BMI',
                  value: user.bmi?.toStringAsFixed(1) ?? '—',
                  icon: Icons.calculate_outlined,
                ),
                _LabeledValue(
                  label: '教育程度',
                  value: user.educationLevel ?? '—',
                  icon: Icons.school_outlined,
                ),
                _LabeledValue(
                  label: '更新時間',
                  value: formatDateTime(user.updatedAt),
                  icon: Icons.update_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '備註',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (user.notes ?? '').trim().isEmpty ? '—' : user.notes!.trim(),
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledGrid extends StatelessWidget {
  const _LabeledGrid({required this.children});

  final List<_LabeledValue> children;

  @override
  Widget build(BuildContext context) {
    final columns = context.isDesktopWide ? 2 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
