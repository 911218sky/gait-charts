import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 通用的下拉選單，提供懸浮、陰影與選中標記。
///
/// - 設計意圖：過去版本偏向「只支援深色」，在淺色模式會出現白字白底/邊框消失的問題。
/// - 目前做法：統一改為依 Theme/ColorScheme 自動適配淺/深色，避免在 UI 端硬編顏色。
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.itemLabelBuilder,
    this.menuWidth,
    this.tooltip = '',
    this.enabled = true,
  });

  /// 目前選中的值
  final T value;

  /// 選項列表
  final List<T> items;

  /// 當選項改變時的回呼。若為 null 則視為禁用。
  final ValueChanged<T>? onChanged;

  /// 自訂選項顯示文字的 Builder。若未提供，預設使用 `toString()`。
  final String Function(T item)? itemLabelBuilder;

  /// 下拉選單的寬度限制
  final BoxConstraints? menuWidth;

  /// 按鈕的 Tooltip 提示文字
  final String tooltip;

  /// 是否啟用
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final effectiveLabelBuilder = itemLabelBuilder ?? (item) => item.toString();
    final displayValue = effectiveLabelBuilder(value);
    final isEnabled = enabled && onChanged != null;
    final selectionValue = _SelectValue<T>(value);
    final effectiveTooltip = tooltip.isEmpty ? null : tooltip;

    final menuBackground = colors.surface;
    final menuBorder = colors.outline.withValues(alpha: isDark ? 0.7 : 1);
    final menuShadow = Colors.black.withValues(alpha: isDark ? 0.5 : 0.14);
    final textColor = isEnabled ? colors.onSurface : colors.onSurface.withValues(alpha: 0.38);
    final mutedText = colors.onSurfaceVariant;

    return SizedBox(
      height: 40,
      child: PopupMenuButton<_SelectValue<T>>(
        tooltip: effectiveTooltip,
        initialValue: selectionValue,
        enabled: isEnabled,
        offset: const Offset(0, 42), // 讓選單稍微向下偏移，不遮擋按鈕
        color: menuBackground,
        elevation: 8,
        shadowColor: menuShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: menuBorder,
            width: 1,
          ),
        ),
        constraints:
            menuWidth ?? const BoxConstraints(minWidth: 120, maxWidth: 200),
        // 使用包裝值避免 PopupMenuButton 將 null 當作取消事件。
        onSelected: (selected) => onChanged?.call(selected.value),
        itemBuilder: (context) => items.map((item) {
          final entryValue = _SelectValue<T>(item);
          final isSelected = selectionValue == entryValue;
          final label = effectiveLabelBuilder(item);
          return PopupMenuItem<_SelectValue<T>>(
            value: entryValue,
            height: 36, // 較緊湊的高度
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? colors.onSurface : mutedText,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 14, color: colors.onSurface),
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isEnabled
                  ? colors.outline
                  : colors.outline.withValues(alpha: 0.6),
            ),
            color: isEnabled
                ? Colors.transparent
                : colors.onSurface.withValues(alpha: isDark ? 0.06 : 0.03),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: context.textTheme.bodyMedium?.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isEnabled
                    ? mutedText.withValues(alpha: 0.9)
                    : mutedText.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 封裝 PopupMenuButton 的值，確保 null 也能被選取而非視為取消。
class _SelectValue<T> {
  const _SelectValue(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SelectValue<T> && other.value == value;

  @override
  int get hashCode => value == null ? 0 : value.hashCode;
}
