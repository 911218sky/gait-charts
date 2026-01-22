import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 響應式按鈕群組。
///
/// 根據螢幕寬度自動調整按鈕排列方式：
/// - 寬螢幕：水平排列
/// - 窄螢幕：垂直堆疊或收納至 PopupMenu
///
/// 使用方式：
/// ```dart
/// ResponsiveButtonGroup(
///   buttons: [
///     ResponsiveButton(
///       icon: Icons.edit,
///       label: '編輯',
///       onPressed: _onEdit,
///     ),
///     ResponsiveButton(
///       icon: Icons.delete,
///       label: '刪除',
///       onPressed: _onDelete,
///       isDestructive: true,
///     ),
///   ],
/// )
/// ```
class ResponsiveButtonGroup extends StatelessWidget {
  const ResponsiveButtonGroup({
    required this.buttons,
    this.spacing = 12,
    this.runSpacing = 12,
    this.alignment = WrapAlignment.start,
    this.collapseToMenuOnMobile = false,
    this.menuIcon = Icons.more_vert,
    this.menuTooltip = '更多操作',
    super.key,
  });

  /// 按鈕列表。
  final List<ResponsiveButton> buttons;

  /// 按鈕間距。
  final double spacing;

  /// 換行間距。
  final double runSpacing;

  /// 對齊方式。
  final WrapAlignment alignment;

  /// 是否在手機版收納到 PopupMenu。
  final bool collapseToMenuOnMobile;

  /// PopupMenu 圖示。
  final IconData menuIcon;

  /// PopupMenu tooltip。
  final String menuTooltip;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // 手機版且啟用收納
    if (isMobile && collapseToMenuOnMobile) {
      return _buildPopupMenu(context);
    }

    // 使用 Wrap 自動換行
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: buttons.map((btn) => btn.build(context)).toList(),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final colors = context.colorScheme;

    return PopupMenuButton<int>(
      icon: Icon(menuIcon),
      tooltip: menuTooltip,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final btn = entry.value;
        return PopupMenuItem<int>(
          value: index,
          enabled: btn.onPressed != null,
          child: Row(
            children: [
              Icon(
                btn.icon,
                size: 20,
                color: btn.isDestructive
                    ? colors.error
                    : btn.onPressed == null
                        ? colors.onSurface.withValues(alpha: 0.38)
                        : colors.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                btn.label,
                style: TextStyle(
                  color: btn.isDestructive
                      ? colors.error
                      : btn.onPressed == null
                          ? colors.onSurface.withValues(alpha: 0.38)
                          : colors.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (index) {
        final btn = buttons[index];
        btn.onPressed?.call();
      },
    );
  }
}

/// 響應式按鈕資料。
class ResponsiveButton {
  const ResponsiveButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
    this.isOutlined = true,
  });

  /// 按鈕圖示。
  final IconData icon;

  /// 按鈕文字。
  final String label;

  /// 點擊回調。
  final VoidCallback? onPressed;

  /// 是否為破壞性操作（如刪除）。
  final bool isDestructive;

  /// 是否為主要按鈕（使用 FilledButton）。
  final bool isPrimary;

  /// 是否為外框按鈕（使用 OutlinedButton）。
  final bool isOutlined;

  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: isDestructive
            ? FilledButton.styleFrom(backgroundColor: colors.error)
            : null,
      );
    }

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: isDestructive
            ? OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
              )
            : null,
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: isDestructive
          ? TextButton.styleFrom(foregroundColor: colors.error)
          : null,
    );
  }
}
