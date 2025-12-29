import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/navigation/dashboard_header_actions.dart';

/// Header 區塊，包含 session 控制 與查詢設定。
class YHeightDiffHeader extends ConsumerWidget {
  const YHeightDiffHeader({
    required this.sessionController,
    required this.onLoadSession,
    required this.isLoading,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final activeSession = ref.watch(activeSessionProvider);

    Future<void> browseSessions() async {
      final selected = await SessionPickerDialog.show(context);
      if (selected == null || selected.isEmpty || !context.mounted) {
        return;
      }
      sessionController.text = selected;
      onLoadSession();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        const settings = Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _YHeightSmoothWindowSelector(),
            _YHeightJointSelector(
              label: '左側關節 (MP Pose 索引)',
              side: _JointSide.left,
            ),
            _YHeightJointSelector(
              label: '右側關節 (MP Pose 索引)',
              side: _JointSide.right,
            ),
            _YHeightPresetButtons(),
            _YHeightShiftToggle(),
            _YHeightConfigResetButton(),
          ],
        );

        return Container(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          decoration: BoxDecoration(
            color: context.scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: context.dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCompact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Height Symmetry Monitor',
                            style: context.textTheme.headlineSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '檢視左右關節的 Y 軸高度與差值，快速比對步態對稱性。',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    DashboardHeaderActions(activeSession: activeSession),
                  ],
                )
              else ...[
                Text(
                  'Height Symmetry Monitor',
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '檢視左右關節的 Y 軸高度與差值，快速比對步態對稱性。',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: DashboardHeaderActions(activeSession: activeSession),
                ),
              ],
              const SizedBox(height: 20),
              if (!isCompact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: SessionAutocompleteField(
                        controller: sessionController,
                        labelText: 'Session 名稱',
                        hintText: '例如：patient_2025_1101',
                        enabled: !isLoading,
                        onSubmitted: isLoading ? null : (_) => onLoadSession(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : browseSessions,
                      icon: const Icon(Icons.search),
                      label: const Text('瀏覽 Sessions'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: isLoading ? null : onLoadSession,
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.monitor_heart),
                      label: Text(isLoading ? '載入中' : '載入高度差'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SessionAutocompleteField(
                      controller: sessionController,
                      labelText: 'Session 名稱',
                      hintText: '例如：patient_2025_1101',
                      enabled: !isLoading,
                      onSubmitted: isLoading ? null : (_) => onLoadSession(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : browseSessions,
                          icon: const Icon(Icons.search),
                          label: const Text('瀏覽'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: isLoading ? null : onLoadSession,
                          icon: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.monitor_heart),
                          label: Text(isLoading ? '載入中' : '載入高度差'),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              if (!isCompact)
                settings
              else
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 12),
                  title: Text(
                    '查詢設定',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '平滑 / 關節 / 預設',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  children: const [settings],
                ),
              const SizedBox(height: 6),
              Text(
                '採用 MediaPipe Pose 關節索引（預設 27 / 28 左右踝），可依需求改選不同關節點位。',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _YHeightSmoothWindowSelector extends ConsumerWidget {
  const _YHeightSmoothWindowSelector();

  static const _min = 1;
  static const _max = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final value = ref.watch(
      yHeightDiffConfigProvider.select((config) => config.smoothWindow),
    );
    final notifier = ref.read(yHeightDiffConfigProvider.notifier);

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '平滑視窗',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$value',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            onChanged: (v) =>
                notifier.updateSmoothWindow(v.round().clamp(_min, _max)),
            min: _min.toDouble(),
            max: _max.toDouble(),
            divisions: _max - _min,
            label: '$value',
          ),
        ],
      ),
    );
  }
}

class _YHeightJointSelector extends ConsumerWidget {
  const _YHeightJointSelector({required this.label, required this.side});

  final String label;
  final _JointSide side;

  static const _jointOptions = [
    _JointOption(0, '鼻 (nose)'),
    // 上半身關節
    _JointOption(1, '左眼內 (left eye inner)'),
    _JointOption(2, '左眼 (left eye)'),
    _JointOption(3, '左眼外 (left eye outer)'),
    _JointOption(4, '右眼內 (right eye inner)'),
    _JointOption(5, '右眼 (right eye)'),
    _JointOption(6, '右眼外 (right eye outer)'),
    _JointOption(7, '左耳 (left ear)'),
    _JointOption(8, '右耳 (right ear)'),
    _JointOption(9, '嘴角左 (mouth left)'),
    _JointOption(10, '嘴角右 (mouth right)'),
    _JointOption(11, '左肩 (left shoulder)'),
    _JointOption(12, '右肩 (right shoulder)'),
    _JointOption(13, '左肘 (left elbow)'),
    _JointOption(14, '右肘 (right elbow)'),
    _JointOption(15, '左腕 (left wrist)'),
    _JointOption(16, '右腕 (right wrist)'),
    _JointOption(17, '左小指 (left pinky)'),
    _JointOption(18, '右小指 (right pinky)'),
    _JointOption(19, '左食指 (left index)'),
    _JointOption(20, '右食指 (right index)'),
    _JointOption(21, '左拇指 (left thumb)'),
    _JointOption(22, '右拇指 (right thumb)'),
    // 下半身關節
    _JointOption(23, '左髖 (left hip)'),
    _JointOption(24, '右髖 (right hip)'),
    _JointOption(25, '左膝 (left knee)'),
    _JointOption(26, '右膝 (right knee)'),
    _JointOption(27, '左踝 (left ankle)'),
    _JointOption(28, '右踝 (right ankle)'),
    _JointOption(29, '左腳跟 (left heel)'),
    _JointOption(30, '右腳跟 (right heel)'),
    _JointOption(31, '左腳趾尖 (left foot index)'),
    _JointOption(32, '右腳趾尖 (right foot index)'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final value = ref.watch(
      yHeightDiffConfigProvider.select(
        (config) =>
            side == _JointSide.left ? config.leftJoint : config.rightJoint,
      ),
    );
    final notifier = ref.read(yHeightDiffConfigProvider.notifier);

    // 建立一個選項映射，方便顯示
    final optionsMap = {for (final e in _jointOptions) e.index: e};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 220,
          child: AppSelect<int>(
            value: value,
            items: _jointOptions.map((e) => e.index).toList(),
            onChanged: (v) {
              if (side == _JointSide.left) {
                notifier.updateLeftJoint(v);
              } else {
                notifier.updateRightJoint(v);
              }
            },
            itemLabelBuilder: (index) {
              final option = optionsMap[index];
              return option != null
                  ? '${option.index} – ${option.label}'
                  : '$index';
            },
            menuWidth: const BoxConstraints(minWidth: 200, maxWidth: 280),
          ),
        ),
      ],
    );
  }
}

class _YHeightConfigResetButton extends ConsumerWidget {
  const _YHeightConfigResetButton();

  static const _defaultSmoothWindow = 3;
  static const _defaultLeftJoint = 27;
  static const _defaultRightJoint = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final isDefault = ref.watch(
      yHeightDiffConfigProvider.select(
        (config) =>
            config.smoothWindow == _defaultSmoothWindow &&
            config.leftJoint == _defaultLeftJoint &&
            config.rightJoint == _defaultRightJoint,
      ),
    );
    final notifier = ref.read(yHeightDiffConfigProvider.notifier);

    return TextButton.icon(
      onPressed: isDefault ? null : notifier.reset,
      style: TextButton.styleFrom(foregroundColor: colors.onSurfaceVariant),
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('重置設定'),
    );
  }
}

class _JointOption {
  const _JointOption(this.index, this.label);

  final int index;
  final String label;
}

enum _JointSide { left, right }

class _YHeightPresetButtons extends ConsumerWidget {
  const _YHeightPresetButtons();

  static const _presets = [
    (label: '踝 (27/28)', left: 27, right: 28),
    (label: '膝 (25/26)', left: 25, right: 26),
    (label: '髖 (23/24)', left: 23, right: 24),
    (label: '腳跟 (29/30)', left: 29, right: 30),
    (label: '腳尖 (31/32)', left: 31, right: 32),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final config = ref.watch(yHeightDiffConfigProvider);
    final notifier = ref.read(yHeightDiffConfigProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速套用關節組合',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _presets)
              Builder(
                builder: (context) {
                  final isSelected =
                      config.leftJoint == p.left &&
                      config.rightJoint == p.right;
                  final bgColor = isSelected
                      ? accent.success.withValues(alpha: 0.12)
                      : colors.surfaceContainerLow;
                  final borderColor =
                      isSelected ? accent.success : colors.outlineVariant;
                  final fgColor =
                      isSelected ? colors.onSurface : colors.onSurfaceVariant;
                  return OutlinedButton(
                    onPressed: () => notifier.applyPreset(
                      leftJoint: p.left,
                      rightJoint: p.right,
                      smoothWindow: 3, // 套用預設平滑窗口 3
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fgColor,
                      backgroundColor: bgColor,
                      side: BorderSide(color: borderColor),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    child: Text(p.label),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _YHeightShiftToggle extends ConsumerWidget {
  const _YHeightShiftToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final value = ref.watch(
      yHeightDiffConfigProvider.select((c) => c.shiftToZero),
    );
    final notifier = ref.read(yHeightDiffConfigProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '平移到 0 起點',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(value: value, onChanged: notifier.updateShiftToZero),
      ],
    );
  }
}
