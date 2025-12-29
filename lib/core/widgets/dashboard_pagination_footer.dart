import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 共用分頁列（頁碼按鈕 + 上一頁/下一頁）。
///
/// - `totalPages <= 0` 會自動隱藏。
/// - `onSelectPage` 由外部決定怎麼載入資料。
class DashboardPaginationFooter extends StatelessWidget {
  const DashboardPaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.onSelectPage,
    super.key,
    this.isLoading = false,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 10),
  });

  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final ValueChanged<int> onSelectPage;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final total = totalPages;
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final colors = context.colorScheme;
    final current = currentPage.clamp(1, total);

    final pageSet = <int>{1, total, current - 1, current, current + 1}
        .where((p) => p >= 1 && p <= total)
        .toList()
      ..sort();

    final pageButtons = <Widget>[];
    int? last;
    for (final p in pageSet) {
      if (last != null && p - last > 1) {
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '…',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      final selected = p == current;
      pageButtons.add(
        OutlinedButton(
          onPressed: isLoading || selected ? null : () => onSelectPage(p),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(40, 36),
            backgroundColor:
                selected ? colors.primary.withValues(alpha: 0.12) : null,
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Text('$p', style: const TextStyle(fontSize: 12)),
        ),
      );
      last = p;
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          IconButton(
            tooltip: '上一頁',
            onPressed: isLoading || current <= 1
                ? null
                : () => onSelectPage(current - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: pageButtons,
              ),
            ),
          ),
          IconButton(
            tooltip: '下一頁',
            onPressed: isLoading || current >= total
                ? null
                : () => onSelectPage(current + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}


