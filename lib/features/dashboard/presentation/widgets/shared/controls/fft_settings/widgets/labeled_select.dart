import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';

/// 帶標籤的下拉選單。
class LabeledSelect<T> extends StatelessWidget {
  const LabeledSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
    this.tooltip,
    this.width = 320,
    super.key,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final String? tooltip;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final labelStyle = textTheme.labelMedium?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.7),
      fontWeight: FontWeight.w500,
    );

    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, style: labelStyle, overflow: TextOverflow.ellipsis),
        ),
        if (tooltip != null && tooltip!.isNotEmpty) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.info_outline,
            size: 16,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ],
    );

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tooltip != null && tooltip!.isNotEmpty)
            AppTooltip(message: tooltip!, child: labelWidget)
          else
            labelWidget,
          const SizedBox(height: 10),
          AppSelect<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            itemLabelBuilder: itemLabelBuilder,
            menuWidth: BoxConstraints(minWidth: 140, maxWidth: width),
          ),
        ],
      ),
    );
  }
}
