import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/per_lap_offset/per_lap_offset_content.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/controls/projection_planes.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/navigation/dashboard_header_actions.dart';

/// 顯示 per-lap offset 分析內容的主視圖。
class PerLapOffsetView extends ConsumerStatefulWidget {
  const PerLapOffsetView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  ConsumerState<PerLapOffsetView> createState() => _PerLapOffsetViewState();
}

class _PerLapOffsetViewState extends ConsumerState<PerLapOffsetView> {
  ProviderSubscription<AsyncValue<PerLapOffsetResponse>>? _dataSubscription;
  ProviderSubscription<int?>? _lapSelectionSubscription;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _detailSectionKey = GlobalKey();
  bool _showSamples = false;
  int? _sampleLimit = 120;
  bool _hasSkippedInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _dataSubscription = ref.listenManual<AsyncValue<PerLapOffsetResponse>>(
      perLapOffsetProvider,
      (previous, next) {
        next.whenData((response) {
          final laps = response.laps;
          final notifier = ref.read(perLapOffsetSelectedLapProvider.notifier);
          if (laps.isEmpty) {
            notifier.select(null);
            return;
          }
          final current = ref.read(perLapOffsetSelectedLapProvider);
          final hasCurrent =
              current != null && laps.any((lap) => lap.lapIndex == current);
          if (!hasCurrent) {
            notifier.select(laps.first.lapIndex);
          }
        });
      },
    );

    _lapSelectionSubscription = ref.listenManual<int?>(
      perLapOffsetSelectedLapProvider,
      (previous, next) {
        if (!_hasSkippedInitialScroll) {
          _hasSkippedInitialScroll = true;
          return;
        }
        if (next == null) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToDetail());
      },
    );
  }

  @override
  void dispose() {
    _dataSubscription?.close();
    _lapSelectionSubscription?.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToDetail() {
    final context = _detailSectionKey.currentContext;
    if (context == null || !_scrollController.hasClients) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final perLapAsync = ref.watch(perLapOffsetProvider);
    final perLapFailure = ref.watch(requestFailureProvider('per_lap_offset'));

    void handleLoad() {
      // 使用者再次點擊「載入 Offset」時，視為明確的 retry：
      // 清除 failure gate 並強制刷新 provider（即使 session 沒變也會重打 API）。
      ref.read(requestFailureStoreProvider.notifier).clearFailure(
            'per_lap_offset',
          );
      widget.onLoadSession();
      ref.invalidate(perLapOffsetProvider);
    }

    return ListView(
      controller: _scrollController,
      padding: dashboardPagePadding(context),
      children: [
        _PerLapOffsetHeader(
          sessionController: widget.sessionController,
          onLoadSession: handleLoad,
          // 若 request 已經失敗（failure store 有紀錄），header 不應該繼續顯示「載入中」。
          isLoading: perLapAsync.isLoading && perLapFailure == null,
        ),
        const SizedBox(height: 16),
        AsyncRequestView<PerLapOffsetResponse>(
          requestId: 'per_lap_offset',
          value: perLapAsync,
          loadingLabel: '計算每圈 lateral offset…',
          isEmpty: (response) => response.laps.isEmpty,
          emptyBuilder: (_) => const _PerLapEmptyState(),
          onRetry: () => ref.invalidate(perLapOffsetProvider),
          dataBuilder: (context, response) => PerLapOffsetContent(
            response: response,
            showSamples: _showSamples,
            sampleLimit: _sampleLimit,
            onToggleSamples: (value) => setState(() => _showSamples = value),
            onChangeSampleLimit: (value) => setState(() => _sampleLimit = value),
            detailSectionKey: _detailSectionKey,
          ),
        ),
      ],
    );
  }
}

class _PerLapOffsetHeader extends ConsumerWidget {
  const _PerLapOffsetHeader({
    required this.sessionController,
    required this.onLoadSession,
    required this.isLoading,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final config = ref.watch(perLapOffsetConfigProvider);
    final notifier = ref.read(perLapOffsetConfigProvider.notifier);
    final activeSession = ref.watch(activeSessionProvider);
    final textTheme = context.textTheme;

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

        final settings = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ProjectionSelector(
                  current: config.projection,
                  onChanged: notifier.updateProjection,
                ),
                AppDoubleSliderTile(
                  label: 'smooth_window_s',
                  value: config.smoothWindowSeconds,
                  min: 0,
                  max: 0.8,
                  step: 0.05,
                  width: 340,
                  suffix: 's',
                  onChanged: notifier.updateSmoothWindowSeconds,
                  tooltip: '平滑視窗（秒）。後端已移除 per-lap FFT，本參數僅影響時域平滑。',
                ),
                AppIntSliderTile(
                  label: 'k-smooth',
                  value: config.kSmooth,
                  min: 1,
                  max: 10,
                  onChanged: notifier.updateKSmooth,
                  tooltip: '平滑係數（k_smooth）。後端已移除 per-lap FFT，本參數僅影響時域/區段偵測的平滑。',
                ),
                AppDoubleSliderTile(
                  label: 'min_v_abs',
                  value: config.minVAbs,
                  min: 0,
                  max: 0.3,
                  step: 0.01,
                  width: 340,
                  suffix: 'm/s',
                  onChanged: notifier.updateMinVAbs,
                  tooltip: '速度閾值：低於此速度會被視為靜止段',
                ),
                AppDoubleSliderTile(
                  label: 'flat_frac',
                  value: config.flatFrac,
                  min: 0,
                  max: 1,
                  step: 0.05,
                  onChanged: notifier.updateFlatFrac,
                  tooltip: '平坦比例：用於判斷平坦區段的比例閾值',
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
                            'Lateral Offset Explorer',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '檢視每圈的 lateral offset、頻譜與骨盆朝向變化，調整 FFT 與平滑參數。',
                            style: textTheme.bodyMedium?.copyWith(
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
                  'Lateral Offset Explorer',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '檢視每圈的 lateral offset、頻譜與骨盆朝向變化，調整 FFT 與平滑參數。',
                  style: textTheme.bodyMedium?.copyWith(
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
                        onSubmitted: (_) => onLoadSession(),
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
                          : const Icon(Icons.multiline_chart),
                      label: Text(isLoading ? '載入中' : '載入 Offset'),
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
                      onSubmitted: (_) => onLoadSession(),
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
                              : const Icon(Icons.multiline_chart),
                          label: Text(isLoading ? '載入中' : '載入 Offset'),
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
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '投影 / 平滑 / FFT',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  children: [settings],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PerLapEmptyState extends StatelessWidget {
  const _PerLapEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: context.cardColor,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '尚無每圈偏移資料',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請先載入 session 並確認後端已回傳 per-lap offset 結果。',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
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
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '投影平面',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 170,
          child: AppSelect<String>(
            value: current,
            items: _options,
            onChanged: onChanged,
            itemLabelBuilder: (val) => val.toUpperCase(),
            menuWidth: const BoxConstraints(minWidth: 120, maxWidth: 200),
          ),
        ),
      ],
    );
  }
}
