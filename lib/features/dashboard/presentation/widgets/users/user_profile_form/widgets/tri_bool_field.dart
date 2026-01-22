import 'package:flutter/material.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';

/// 三態布林欄位：未設定 / 是 / 否。
class TriBoolField extends StatelessWidget {
  const TriBoolField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.labelStyle,
    this.width = 200,
    this.enabled = true,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final TextStyle labelStyle;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final current = value == null
        ? TriBoolValue.unset
        : (value! ? TriBoolValue.yes : TriBoolValue.no);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 8),
          // 統一使用共用下拉組件，避免 DropdownButtonFormField 預設樣式問題
          AppSelect<TriBoolValue>(
            value: current,
            items: const [
              TriBoolValue.unset,
              TriBoolValue.yes,
              TriBoolValue.no,
            ],
            enabled: enabled,
            itemLabelBuilder: (item) {
              switch (item) {
                case TriBoolValue.unset:
                  return '未設定';
                case TriBoolValue.yes:
                  return '是';
                case TriBoolValue.no:
                  return '否';
              }
            },
            onChanged: enabled
                ? (next) {
                    switch (next) {
                      case TriBoolValue.unset:
                        onChanged(null);
                      case TriBoolValue.yes:
                        onChanged(true);
                      case TriBoolValue.no:
                        onChanged(false);
                    }
                  }
                : null,
            menuWidth: const BoxConstraints(minWidth: 140, maxWidth: 220),
          ),
        ],
      ),
    );
  }
}

/// 三態布林值列舉。
enum TriBoolValue { unset, yes, no }
