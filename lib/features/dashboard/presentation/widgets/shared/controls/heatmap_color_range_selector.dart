import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

class HeatmapColorRangeSelector extends StatelessWidget {
  const HeatmapColorRangeSelector({
    required this.vmin,
    required this.vmax,
    required this.onChangedMin,
    required this.onChangedMax,
    required this.onAuto,
    this.defaultMin = 0.0,
    this.defaultMax = 3.5,
    this.label = '顏色區間',
    super.key,
  });

  final double? vmin;
  final double? vmax;
  final ValueChanged<double> onChangedMin;
  final ValueChanged<double> onChangedMax;
  final VoidCallback onAuto;
  final double defaultMin;
  final double defaultMax;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isAuto = vmin == null || vmax == null;
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final chipBorderColor =
        isAuto ? colors.primary : colors.outlineVariant.withValues(alpha: 0.9);
    final chipBgColor = isAuto
        ? colors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
        : colors.onSurface.withValues(alpha: isDark ? 0.06 : 0.04);
    final chipFgColor = isAuto ? colors.onSurface : colors.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Auto Toggle
            FilterChip(
              label: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                child: const Text('Auto'),
              ),
              selected: isAuto,
              onSelected: (val) {
                if (val) {
                  onAuto();
                } else {
                  // Switch to Manual: Restore defaults
                  onChangedMin(defaultMin);
                  onChangedMax(defaultMax);
                }
              },
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              labelStyle: TextStyle(color: chipFgColor, letterSpacing: 0.2),
              backgroundColor: chipBgColor,
              selectedColor: chipBgColor,
              side: BorderSide(color: chipBorderColor, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            // Min Input
            SizedBox(
              width: 60,
              child: _NumberInput(
                value: vmin ?? defaultMin,
                enabled: !isAuto,
                onChanged: onChangedMin,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '-',
                style: TextStyle(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Max Input
            SizedBox(
              width: 60,
              child: _NumberInput(
                value: vmax ?? defaultMax,
                enabled: !isAuto,
                onChanged: onChangedMax,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberInput extends StatefulWidget {
  const _NumberInput({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
       final currentParsed = double.tryParse(_ctrl.text);
       if (currentParsed != widget.value) {
         _ctrl.text = _format(widget.value);
       }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: context.textTheme.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: context.dividerColor),
        ),
      ),
      onSubmitted: (val) {
        final d = double.tryParse(val);
        if (d != null) widget.onChanged(d);
      },
      onTapOutside: (_) {
        final d = double.tryParse(_ctrl.text);
        if (d != null) widget.onChanged(d);
      },
    );
  }
}

