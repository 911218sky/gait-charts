import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';

/// 統一的整數滑桿元件，支援 tooltip 說明
class AppIntSliderTile extends StatefulWidget {
  const AppIntSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
    this.tooltip,
    this.helperText,
    this.width = 200,
    this.updateOnChangeEndOnly = true,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool updateOnChangeEndOnly;

  /// 滑鼠懸停時顯示的說明
  final String? tooltip;

  /// 顯示在標籤下方的輔助文字
  final String? helperText;

  /// 元件寬度
  final double width;

  @override
  State<AppIntSliderTile> createState() => _AppIntSliderTileState();
}

class _AppIntSliderTileState extends State<AppIntSliderTile> {
  double? _pendingValue;

  @override
  void didUpdateWidget(covariant AppIntSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _pendingValue = widget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final displayValue = widget.updateOnChangeEndOnly
        ? (_pendingValue ?? widget.value.toDouble()).round()
        : widget.value;
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabel(displayValue),
          if (widget.helperText != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.helperText!,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
          Slider(
            value: (widget.updateOnChangeEndOnly
                    ? (_pendingValue ?? widget.value.toDouble())
                    : widget.value.toDouble())
                .clamp(widget.min.toDouble(), widget.max.toDouble()),
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            divisions: widget.max - widget.min,
            onChanged: (next) {
              if (widget.updateOnChangeEndOnly) {
                setState(() => _pendingValue = next);
                return;
              }
              widget.onChanged(next.round());
            },
            onChangeEnd: widget.updateOnChangeEndOnly
                ? (next) => widget.onChanged(next.round())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(int displayValue) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '${widget.label}：$displayValue',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.82),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.tooltip != null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline,
            size: 14,
            color: colors.onSurfaceVariant.withValues(alpha: 0.9),
          ),
        ],
      ],
    );
    if (widget.tooltip != null) {
      return AppTooltip(message: widget.tooltip!, child: labelWidget);
    }
    return labelWidget;
  }
}

/// 統一的浮點數滑桿元件，支援 tooltip 說明
class AppDoubleSliderTile extends StatefulWidget {
  const AppDoubleSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
    this.step,
    this.tooltip,
    this.suffix,
    this.formatter,
    this.width = 200,
    this.updateOnChangeEndOnly = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// 指定步進值，若設定此值則會自動計算 divisions
  final double? step;

  /// 滑鼠懸停時顯示的說明
  final String? tooltip;

  /// 數值後綴（如 m/s、Hz）
  final String? suffix;

  /// 自訂數值格式化，若未提供則使用小數點後兩位
  final String Function(double)? formatter;

  /// 元件寬度
  final double width;
  final bool updateOnChangeEndOnly;

  @override
  State<AppDoubleSliderTile> createState() => _AppDoubleSliderTileState();
}

class _AppDoubleSliderTileState extends State<AppDoubleSliderTile> {
  double? _pendingValue;

  @override
  void didUpdateWidget(covariant AppDoubleSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _pendingValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue =
        widget.updateOnChangeEndOnly ? (_pendingValue ?? widget.value) : widget.value;
    final display = _formatValue(displayValue);

    // 使用 step
    final divisions = ((widget.max - widget.min) / (widget.step ?? 0.1)).round();

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabel(display),
          Slider(
            value: (widget.updateOnChangeEndOnly
                    ? (_pendingValue ?? widget.value)
                    : widget.value)
                .clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: divisions,
            onChanged: (next) {
              if (widget.updateOnChangeEndOnly) {
                setState(() => _pendingValue = next);
                return;
              }
              widget.onChanged(next);
            },
            onChangeEnd:
                widget.updateOnChangeEndOnly ? (next) => widget.onChanged(next) : null,
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (widget.formatter != null) {
      return widget.formatter!(value);
    }
    // 預設顯示：小數最多 2 位，但會去掉尾端 0（例如 3.00 -> 3、3.10 -> 3.1）。
    final formatted = value.toStringAsFixed(2).replaceFirst(
      RegExp(r'\.?0+$'),
      '',
    );
    return widget.suffix != null ? '$formatted ${widget.suffix}' : formatted;
  }

  Widget _buildLabel(String display) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '${widget.label}：$display',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.82),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.tooltip != null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline,
            size: 14,
            color: colors.onSurfaceVariant.withValues(alpha: 0.9),
          ),
        ],
      ],
    );
    if (widget.tooltip != null) {
      return AppTooltip(message: widget.tooltip!, child: labelWidget);
    }
    return labelWidget;
  }
}

/// 統一的範圍滑桿元件，支援 tooltip 說明
class AppRangeSliderTile extends StatelessWidget {
  const AppRangeSliderTile({
    required this.label,
    required this.low,
    required this.high,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
    this.divisions,
    this.tooltip,
    this.suffix,
    this.width = 220,
  });

  final String label;
  final double low;
  final double high;
  final double min;
  final double max;
  final void Function(double low, double high) onChanged;
  final int? divisions;

  /// 滑鼠懸停時顯示的說明
  final String? tooltip;

  /// 數值後綴（如 Hz）
  final String? suffix;

  /// 元件寬度
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final values = RangeValues(low, high);
    final displaySuffix = suffix != null ? ' $suffix' : '';
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabel(context, displaySuffix, colors),
          RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (next) => onChanged(next.start, next.end),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context,
    String displaySuffix,
    ColorScheme colors,
  ) {
    final textTheme = context.textTheme;
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '$label (${low.toStringAsFixed(1)}–${high.toStringAsFixed(1)}$displaySuffix)',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.82),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline,
            size: 14,
            color: colors.onSurfaceVariant.withValues(alpha: 0.9),
          ),
        ],
      ],
    );
    if (tooltip != null) {
      return AppTooltip(message: tooltip!, child: labelWidget);
    }
    return labelWidget;
  }
}
