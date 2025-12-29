import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 控制信心數值的滑桿元件
class ConfidenceSlider extends StatelessWidget {
  const ConfidenceSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final slider = Slider(
      value: value,
      min: 0.1,
      max: 1,
      divisions: 9,
      label: value.toStringAsFixed(2),
      onChanged: onChanged,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        slider,
      ],
    );
  }
}
