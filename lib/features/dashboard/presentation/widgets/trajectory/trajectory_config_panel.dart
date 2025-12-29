import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/controls/projection_planes.dart';

/// 放置於右側的 Trajectory 設定面板。
class TrajectoryConfigPanel extends ConsumerWidget {
  const TrajectoryConfigPanel({
    super.key,
    this.width = 300,
    this.showSidebarBorder = true,
  });

  /// 預設桌面右側面板使用 300px；若要用在手機 BottomSheet，請傳入 null。
  final double? width;

  /// 右側面板模式下顯示左側分隔線；BottomSheet/內嵌模式可關閉。
  final bool showSidebarBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(trajectoryPayloadConfigProvider);
    final notifier = ref.read(trajectoryPayloadConfigProvider.notifier);
    final overlayUi = ref.watch(trajectoryOverlayUiProvider);
    final overlayNotifier = ref.read(trajectoryOverlayUiProvider.notifier);

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: showSidebarBorder
            ? Border(left: BorderSide(color: context.dividerColor))
            : null,
        color: context.scaffoldBackgroundColor,
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '播放設定',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _ConfigSection(
            title: '關節點位',
            children: const [
              _TrajectoryJointSelector(
                label: '左側關節 (left_joint)',
                side: _JointSide.left,
              ),
              SizedBox(height: 16),
              _TrajectoryJointSelector(
                label: '右側關節 (right_joint)',
                side: _JointSide.right,
              ),
              SizedBox(height: 16),
              _TrajectoryPresetButtons(),
            ],
          ),
          const Divider(height: 32),
          _ConfigSection(
            title: '投影與取樣',
            children: [
              const SizedBox(height: 8),
              _ProjectionSelector(
                current: config.projection,
                onChanged: notifier.updateProjection,
              ),
              const SizedBox(height: 16),
              AppIntSliderTile(
                label: 'fps_out',
                value: config.fpsOut,
                min: 6,
                max: 60,
                onChanged: notifier.updateFpsOut,
                tooltip: '後端建議輸出 fps',
              ),
              AppDoubleSliderTile(
                label: 'speed',
                value: config.speed,
                min: 0.5,
                max: 3.0,
                step: 0.1,
                onChanged: notifier.updateSpeed,
                tooltip: '後端下採樣倍率',
              ),
              AppIntSliderTile(
                label: 'frame_jump',
                value: config.frameJump,
                min: 1,
                max: 10,
                onChanged: notifier.updateFrameJump,
                tooltip: '額外每 N 幀取 1 幀',
              ),
            ],
          ),
          const Divider(height: 32),
          _ConfigSection(
            title: '平滑與畫面',
            children: [
              AppIntSliderTile(
                label: '平滑 (s)',
                value: config.smoothWindow,
                min: 1,
                max: 15,
                onChanged: notifier.updateSmoothWindow,
                tooltip: '關節點位平滑視窗',
              ),
              AppDoubleSliderTile(
                label: 'Padding',
                value: config.padScale,
                min: 0.0,
                max: 0.25,
                step: 0.01,
                onChanged: notifier.updatePadScale,
                tooltip: '邊界留白比例',
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: overlayUi.showChairArea,
                onChanged: overlayNotifier.toggleChairArea,
                title: const Text('顯示椅子區域'),
                subtitle: const Text('顯示椅子安全圈圈'),
              ),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: overlayUi.showConeArea,
                onChanged: overlayNotifier.toggleConeArea,
                title: const Text('顯示錐子區域'),
                subtitle: const Text('顯示錐子安全圈圈'),
              ),
              // rotate_180 移到播放器上，這裡可以保留或隱藏
              // 為了完整性先保留，但設為次要顯示
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: notifier.reset,
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('重置預設值'),
          ),
        ],
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _ProjectionSelector extends StatelessWidget {
  const _ProjectionSelector({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  static const _options = projectionPlaneOptions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('投影平面:', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: AppSelect<String>(
            value: current,
            items: _options,
            onChanged: onChanged,
            itemLabelBuilder: (item) => item.toUpperCase(),
            menuWidth: const BoxConstraints(minWidth: 80, maxWidth: 120),
          ),
        ),
      ],
    );
  }
}

class _TrajectoryJointSelector extends ConsumerWidget {
  const _TrajectoryJointSelector({required this.label, required this.side});

  final String label;
  final _JointSide side;

  // MediaPipe Pose 33 landmarks (0..32)
  static const _jointOptions = [
    _JointOption(0, '鼻 (nose)'),
    // 上半身
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
    // 下半身
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

  static int _fallbackIndexFor(_JointSide side) =>
      side == _JointSide.left ? 23 : 24;

  static int? _tryParseJointIndex(Object spec) {
    if (spec is int) {
      return spec;
    }
    if (spec is String) {
      final parsed = int.tryParse(spec);
      if (parsed != null) return parsed;
      // 兼容後端常用名稱（若使用者/預設仍是字串），映射到 MP Pose index。
      const map = <String, int>{
        'L_HIP': 23,
        'R_HIP': 24,
        'L_KNEE': 25,
        'R_KNEE': 26,
        'L_ANKLE': 27,
        'R_ANKLE': 28,
        'L_HEEL': 29,
        'R_HEEL': 30,
        'L_FOOT_INDEX': 31,
        'R_FOOT_INDEX': 32,
        'L_SHOULDER': 11,
        'R_SHOULDER': 12,
      };
      return map[spec];
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final config = ref.watch(trajectoryPayloadConfigProvider);
    final notifier = ref.read(trajectoryPayloadConfigProvider.notifier);

    final raw = side == _JointSide.left ? config.leftJoint : config.rightJoint;
    final currentIndex = _tryParseJointIndex(raw) ?? _fallbackIndexFor(side);
    final safeValue = currentIndex.clamp(0, 32);
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
          width: 260,
          child: AppSelect<int>(
            value: safeValue,
            items: _jointOptions.map((e) => e.index).toList(),
            tooltip: label,
            onChanged: (v) {
              if (side == _JointSide.left) {
                notifier.updateLeftJoint(v);
              } else {
                notifier.updateRightJoint(v);
              }
            },
            itemLabelBuilder: (index) {
              final option = optionsMap[index];
              return option != null ? '${option.index} – ${option.label}' : '$index';
            },
            menuWidth: const BoxConstraints(minWidth: 240, maxWidth: 320),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '採用 MediaPipe Pose 關節索引 (0..32)。也相容 L_HIP/R_HIP 等名稱（會自動映射）。',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _TrajectoryPresetButtons extends ConsumerWidget {
  const _TrajectoryPresetButtons();

  static const _presets = [
    (label: '踝 (27/28)', left: 27, right: 28),
    (label: '膝 (25/26)', left: 25, right: 26),
    (label: '髖 (23/24)', left: 23, right: 24),
    (label: '腳跟 (29/30)', left: 29, right: 30),
    (label: '腳尖 (31/32)', left: 31, right: 32),
    (label: '肩 (11/12)', left: 11, right: 12),
  ];

  static int _normalize(Object v, int fallback) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final config = ref.watch(trajectoryPayloadConfigProvider);
    final notifier = ref.read(trajectoryPayloadConfigProvider.notifier);

    // 用 index 去比對是否選中（避免 config 仍是字串時無法高亮）。
    final leftIndex = _normalize(config.leftJoint, 23);
    final rightIndex = _normalize(config.rightJoint, 24);

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
                  final isSelected = leftIndex == p.left && rightIndex == p.right;
                  final bgColor = isSelected
                      ? accent.success.withValues(alpha: 0.12)
                      : colors.surfaceContainerLow;
                  final borderColor =
                      isSelected ? accent.success : colors.outlineVariant;
                  final fgColor =
                      isSelected ? colors.onSurface : colors.onSurfaceVariant;
                  return OutlinedButton(
                    onPressed: () => notifier.applyJointPreset(
                      leftJoint: p.left,
                      rightJoint: p.right,
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
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

class _JointOption {
  const _JointOption(this.index, this.label);

  final int index;
  final String label;
}

enum _JointSide { left, right }

