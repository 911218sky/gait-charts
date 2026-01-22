import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';

/// 批量刪除 Cohort Benchmarks 的選取/確認/結果 Dialog。
class BatchDeleteCohortBenchmarkDialog {
  /// 讓使用者在 dialog 內勾選要刪除的 cohorts，確認後回傳選取清單。
  static Future<List<String>?> pickAndConfirm(
    BuildContext context, {
    required List<String> cohortNames,
  }) {
    final normalized = cohortNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return showDialog<List<String>>(
      context: context,
      builder: (_) => _PickAndConfirmDialog(cohortNames: normalized),
    );
  }

  static Future<void> showResult(
    BuildContext context, {
    required CohortBenchmarkDeleteBatchResponse response,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _BatchDeleteResultDialog(response: response),
    );
  }
}

class _PickAndConfirmDialog extends StatefulWidget {
  const _PickAndConfirmDialog({required this.cohortNames});

  final List<String> cohortNames;

  @override
  State<_PickAndConfirmDialog> createState() => _PickAndConfirmDialogState();
}

class _PickAndConfirmDialogState extends State<_PickAndConfirmDialog> {
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    // 預設全選，減少刪除時的點擊成本；使用者可手動取消。
    _selected.addAll(widget.cohortNames);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final total = widget.cohortNames.length;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
      header: DashboardDialogHeader(
        title: '批量刪除族群基準值',
        subtitle: '勾選要刪除的 cohorts（已計算的基準值）。此動作無法復原。',
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: total == 0
                      ? null
                      : () => setState(() {
                            _selected
                              ..clear()
                              ..addAll(widget.cohortNames);
                          }),
                  icon: const Icon(Icons.select_all),
                  label: const Text('全選'),
                ),
                OutlinedButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => setState(_selected.clear),
                  icon: const Icon(Icons.clear),
                  label: const Text('清除'),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.outlineVariant),
                    color: colors.surfaceContainerLow,
                  ),
                  child: Text(
                    '已選取 ${_selected.length} / $total',
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
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
                  itemCount: widget.cohortNames.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outlineVariant),
                  itemBuilder: (context, index) {
                    final name = widget.cohortNames[index];
                    final checked = _selected.contains(name);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selected.add(name);
                        } else {
                          _selected.remove(name);
                        }
                      }),
                      title: Text(
                        name,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => context.navigator.pop(
                        _selected.toList(growable: false)..sort(),
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: accent.danger,
                foregroundColor: Colors.white,
              ),
              child: Text('確認刪除（${_selected.length}）'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchDeleteResultDialog extends StatelessWidget {
  const _BatchDeleteResultDialog({required this.response});

  final CohortBenchmarkDeleteBatchResponse response;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    final deleted = response.deleted;
    final notFound = response.notFound ?? const <String>[];

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
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Deleted',
                    value: '${response.deletedCount}',
                    valueColor: response.deletedCount > 0 ? accent.success : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Not found',
                    value: '${notFound.length}',
                    valueColor: notFound.isNotEmpty ? accent.warning : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Deleted（${deleted.length}）',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                  color: colors.surfaceContainerLow,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    deleted.isEmpty ? '（無）' : deleted.join('\n'),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            if (notFound.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Not found（${notFound.length}）',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                  color: colors.surfaceContainerLow,
                ),
                child: Text(
                  notFound.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
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


