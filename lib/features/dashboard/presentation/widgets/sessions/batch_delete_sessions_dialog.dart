import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';

/// 批量刪除 Sessions 的確認/結果對話框。
class BatchDeleteSessionsDialog {
  static Future<bool?> confirm(
    BuildContext context, {
    required List<String> sessionNames,
  }) {
    final normalized = sessionNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          _BatchDeleteSessionsConfirmDialog(sessionNames: normalized),
    );
  }

  static Future<void> showResult(
    BuildContext context, {
    required DeleteSessionsBatchResponse response,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          _BatchDeleteSessionsResultDialog(response: response),
    );
  }
}

class _BatchDeleteSessionsConfirmDialog extends StatelessWidget {
  const _BatchDeleteSessionsConfirmDialog({required this.sessionNames});

  final List<String> sessionNames;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final count = sessionNames.length;
    final preview = sessionNames.take(12).toList(growable: false);
    final rest = count - preview.length;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
      header: DashboardDialogHeader(
        title: '批量刪除 Sessions',
        subtitle: '即將刪除 $count 個 sessions。此動作無法復原。',
        trailing: IconButton(
          tooltip: '關閉',
          onPressed: () => context.navigator.pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '將嘗試刪除：DB / npy / video / bag（若 bag 無其他引用則一併刪除）。',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                  color: colors.surfaceContainerLow,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: preview.length + (rest > 0 ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    if (rest > 0 && index == preview.length) {
                      return Text(
                        '… 其餘 $rest 筆略',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      );
                    }
                    final name = preview[index];
                    return Text(
                      name,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ),
          ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.navigator.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: accent.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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

class _BatchDeleteSessionsResultDialog extends StatelessWidget {
  const _BatchDeleteSessionsResultDialog({required this.response});

  final DeleteSessionsBatchResponse response;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final failed = response.failed;
    final details = response.details;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
      header: DashboardDialogHeader(
        title: '批量刪除結果',
        trailing: IconButton(
          tooltip: '關閉',
          onPressed: () => context.navigator.pop(),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部摘要卡片
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Requested',
                    value: '${response.totalRequested}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Deleted',
                    value: '${response.deletedSessions}',
                    valueColor: accent.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Failed',
                    value: '${failed.length}',
                    valueColor: failed.isNotEmpty ? accent.danger : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 資源刪除統計
            Text(
              '資源刪除統計',
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ResourceStat(
                  label: 'DB',
                  count: response.deletedDb,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                _ResourceStat(
                  label: 'NPY',
                  count: response.deletedNpy,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                _ResourceStat(
                  label: 'Video',
                  count: response.deletedVideo,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                _ResourceStat(
                  label: 'Bag',
                  count: response.deletedBag,
                  color: colors.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 失敗列表
            if (failed.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accent.danger.withValues(alpha: 0.1),
                  border: Border.all(
                    color: accent.danger.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: accent.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '刪除失敗（${failed.length}）',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accent.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      failed.join('\n'),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 明細列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '明細（${details.length}）',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                  color: colors.surfaceContainerLow,
                ),
                child: details.isEmpty
                    ? Center(
                        child: Text(
                          '（後端未回傳明細）',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: details.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: colors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (context, index) {
                          final d = details[index];
                          return _DetailItem(item: d);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: () => context.navigator.pop(),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceStat extends StatelessWidget {
  const _ResourceStat({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.item});

  final DeleteSessionsBatchDetail item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.sessionName,
              style: context.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          _StatusBadge(label: 'DB', isDeleted: item.deletedDb),
          const SizedBox(width: 6),
          _StatusBadge(label: 'NPY', isDeleted: item.deletedNpy),
          const SizedBox(width: 6),
          _StatusBadge(label: 'VID', isDeleted: item.deletedVideo),
          const SizedBox(width: 6),
          _StatusBadge(label: 'BAG', isDeleted: item.deletedBag),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isDeleted});

  final String label;
  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    // 如果已刪除，用綠色；否則用低調的灰色
    final bgColor = isDeleted
        ? accent.success.withValues(alpha: 0.15)
        : colors.surfaceContainerHighest;
    final textColor = isDeleted
        ? accent.success
        : colors.onSurfaceVariant.withValues(alpha: 0.5);
    final borderColor = isDeleted
        ? accent.success.withValues(alpha: 0.3)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
