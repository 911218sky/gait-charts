import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/controls/projection_planes.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/navigation/dashboard_header_actions.dart';

/// trajectory_playback 的 Header：session 輸入 + trajectory payload 設定。
class TrajectoryPlaybackHeader extends ConsumerWidget {
  const TrajectoryPlaybackHeader({
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
    final config = ref.watch(trajectoryPayloadConfigProvider);
    final notifier = ref.read(trajectoryPayloadConfigProvider.notifier);

    Future<void> browseSessions() async {
      final selected = await SessionPickerDialog.show(context);
      if (selected == null || selected.isEmpty || !context.mounted) {
        return;
      }
      sessionController.text = selected;
      onLoadSession();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trajectory Playback',
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '以點位重建 top-down 行走軌跡，前端用 Canvas 播放並標註椅/錐與轉身區段。',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              DashboardHeaderActions(
                activeSession: activeSession,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    : const Icon(Icons.play_circle_outline),
                label: Text(isLoading ? '載入中' : '載入軌跡'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ProjectionSelector(
                current: config.projection,
                onChanged: notifier.updateProjection,
              ),
              AppIntSliderTile(
                label: '平滑視窗 (s)',
                value: config.smoothWindow,
                min: 1,
                max: 15,
              onChanged: notifier.updateSmoothWindow,
              updateOnChangeEndOnly: true,
                tooltip: '關節點位平滑視窗（越大越平順）',
              ),
              AppIntSliderTile(
                label: 'fps_out',
                value: config.fpsOut,
                min: 6,
                max: 60,
              onChanged: notifier.updateFpsOut,
              updateOnChangeEndOnly: true,
                tooltip: '後端建議輸出 fps；也會影響下採樣 stride',
              ),
              AppDoubleSliderTile(
                label: 'speed',
                value: config.speed,
                min: 0.5,
                max: 3.0,
                step: 0.1,
                onChanged: notifier.updateSpeed,
                updateOnChangeEndOnly: true,
                tooltip: '後端下採樣倍率；越大代表取樣越稀疏（點數更少）',
              ),
              AppIntSliderTile(
                label: 'frame_jump',
                value: config.frameJump,
                min: 1,
                max: 10,
              onChanged: notifier.updateFrameJump,
              updateOnChangeEndOnly: true,
                tooltip: '額外每 N 幀取 1 幀（再下採樣一次）',
              ),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                value: config.rotate180,
                onChanged: notifier.updateRotate180,
                title: const Text('rotate_180'),
                subtitle: Text(
                  '以 bounds 中心旋轉 180°，對齊既有影片視角',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              AppDoubleSliderTile(
                label: 'pad_scale',
                value: config.padScale,
                min: 0.0,
                max: 0.25,
                step: 0.01,
                onChanged: notifier.updatePadScale,
                tooltip: 'bounds 額外 padding 比例（避免軌跡貼邊）',
              ),
              TextButton.icon(
                onPressed: notifier.reset,
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重置設定'),
              ),
            ],
          ),
        ],
      ),
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
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '投影平面',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 180,
          child: AppSelect<String>(
            value: current,
            items: _options,
            onChanged: onChanged,
            itemLabelBuilder: (item) => item.toUpperCase(),
            menuWidth: const BoxConstraints(minWidth: 120, maxWidth: 200),
          ),
        ),
      ],
    );
  }
}


