import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/app/theme.dart';

/// 定義側邊欄目的圖示與文字。
class SidebarDestination {
  const SidebarDestination({
    required this.icon,
    required this.label,
    this.groupLabel,
  });

  final IconData icon;
  final String label;
  final String? groupLabel;
}

/// 桌面版儀表板使用的側邊導覽列。
class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
    this.onSettingsTap,
    this.onConnectionSettingsTap,
    this.onLogoutTap,
  });

  final List<SidebarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onConnectionSettingsTap;
  final VoidCallback? onLogoutTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    // 淺色模式下 sidebar 用白底更像 Vercel 風格；深色維持黑底避免整片灰。
    final backgroundColor =
        context.isDark ? context.scaffoldBackgroundColor : colors.surface;
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 1),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(right: BorderSide(color: context.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 24),
            child: Text(
              'Gait Charts',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              primary: false,
              children: _buildNavChildren(
                context,
                destinations: destinations,
                selectedIndex: selectedIndex,
                onChanged: onChanged,
              ),
            ),
          ),
          Divider(color: context.dividerColor, height: 32),
          _SidebarNavItem(
            destination: SidebarDestination(
              icon: context.isDark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              label: '切換主題',
            ),
            active: false,
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(height: 4),
          _SidebarNavItem(
            destination: const SidebarDestination(
              icon: Icons.tune,
              label: 'Chart Settings',
            ),
            active: false,
            onTap: onSettingsTap ?? () {},
          ),
          const SizedBox(height: 4),
          _SidebarNavItem(
            destination: const SidebarDestination(
              icon: Icons.settings_ethernet,
              label: '連線設定',
            ),
            active: false,
            onTap: onConnectionSettingsTap ?? () {},
          ),
          const SizedBox(height: 4),
          _SidebarNavItem(
            destination: const SidebarDestination(
              icon: Icons.logout,
              label: '登出',
            ),
            active: false,
            onTap: onLogoutTap ?? () {},
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavChildren(
    BuildContext context, {
    required List<SidebarDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    final children = <Widget>[];
    String? lastGroup;
    for (var i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      final group = dest.groupLabel;
      if (group != null && group != lastGroup) {
        children.add(_SidebarGroupHeader(label: group));
        children.add(const SizedBox(height: 6));
        lastGroup = group;
      }
      children.add(
        _SidebarNavItem(
          destination: dest,
          active: i == selectedIndex,
          onTap: () => onChanged(i),
        ),
      );
    }
    return children;
  }
}

class _SidebarGroupHeader extends StatelessWidget {
  const _SidebarGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.9),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// 單一側邊欄目的呈現。
class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final SidebarDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final activeColor = colors.primary;
    final inactiveColor = colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: active ? activeColor.withValues(alpha: 0.10) : null,
          ),
          child: Row(
            children: [
              Icon(
                destination.icon,
                size: 18,
                color: active ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 12),
              Text(
                destination.label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: active ? activeColor : inactiveColor,
                  fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
