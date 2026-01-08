import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 可固定在頂部的 Tab Bar delegate。
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  StickyTabBarDelegate({
    required this.activeTabId,
    required this.onTabSelected,
    required this.tabs,
    required this.colors,
  });

  final String activeTabId;
  final ValueChanged<String> onTabSelected;
  final List<(String, String)> tabs;
  final ColorScheme colors;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: context.theme.scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = activeTabId == t.$1;
            return InkWell(
              onTap: () => onTabSelected(t.$1),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  border: isActive
                      ? Border.all(color: colors.primary.withValues(alpha: 0.2))
                      : null,
                ),
                child: Text(
                  t.$2,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate oldDelegate) {
    return activeTabId != oldDelegate.activeTabId;
  }
}
