import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/platform/platform_env.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/domain/feature_availability.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/extraction/bag_picker_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/extraction/extraction_config_controls.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/extraction/extraction_file_list.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/extraction/extraction_progress.dart';

/// 資料提取面板，用於執行 Realsense Pose Extractor（支援多檔案批次處理）。
class ExtractionPanel extends ConsumerStatefulWidget {
  const ExtractionPanel({
    required this.suggestedSession,
    required this.onCompleted,
    super.key,
  });

  final String suggestedSession;
  final ValueChanged<ExtractResult> onCompleted;

  @override
  ConsumerState<ExtractionPanel> createState() => _ExtractionPanelState();
}

class _ExtractionPanelState extends ConsumerState<ExtractionPanel> {
  void _showToast(
    String message, {
    DashboardToastVariant variant = DashboardToastVariant.info,
  }) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  /// 選擇多個 bag 檔案
  Future<void> _pickBagFiles() async {
    try {
      // 這裡不直接在 build 內觸發 API；由 dialog 內的 provider 於 postFrame 載入。
      final selected = await BagPickerDialog.show(
        context,
        // 避免一次塞太多導致 UI 難以管理；需要更大可再調整。
        maxSelection: 200,
      );
      if (!mounted || selected == null || selected.isEmpty) {
        return;
      }

      ref.read(batchExtractionControllerProvider.notifier).addBags(selected);
    } catch (error) {
      _showToast('檔案選擇失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  /// 選擇多個本機 bag 檔案（僅桌面可用；本機來源會以 bag_path 傳遞）
  Future<void> _pickLocalBagFiles() async {
    final env = PlatformEnv.current();
    final message = const DashboardFeatureAvailability().blockedMessage(
      feature: DashboardFeature.extractionLocalBag,
      env: env,
    );
    if (message != null) {
      _showToast(message, variant: DashboardToastVariant.warning);
      return;
    }

    const typeGroup = XTypeGroup(label: 'Bag files', extensions: ['bag']);
    try {
      final files = await openFiles(acceptedTypeGroups: [typeGroup]);
      if (!mounted || files.isEmpty) {
        return;
      }
      final paths = files.map((f) => f.path).toList(growable: false);
      ref.read(batchExtractionControllerProvider.notifier).addLocalFiles(paths);
    } catch (error) {
      _showToast('本機檔案選擇失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _startBatchProcessing() async {
    // 提前讀取 provider 避免 await 期間 widget 被移除後再觸發 ref 讀取
    final config = ref.read(extractConfigProvider);
    final batchNotifier = ref.read(batchExtractionControllerProvider.notifier);

    await batchNotifier.startProcessing(config: config);
    if (!mounted) return;

    // 處理完成後通知上層 (如果有成功的結果)
    final state = ref.read(batchExtractionControllerProvider);
    for (final item in state.items) {
      if (item.status == FileExtractionStatus.success && item.result != null) {
        widget.onCompleted(item.result!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final config = ref.watch(extractConfigProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題區塊
            _buildHeader(context, colors, config.maxConcurrency),
            const SizedBox(height: 24),

            // 檔案區（會跟著 items 狀態更新）
            _ExtractionFilesSection(
              onPickFiles: _pickBagFiles,
              onPickLocalFiles: _pickLocalBagFiles,
              maxConcurrency: config.maxConcurrency,
            ),

            const SizedBox(height: 24),

            // 設定控制區（只跟著 config / isProcessing 變化，不會因每個檔案進度而重建）
            const _ExtractionConfigSection(),

            const SizedBox(height: 24),

            // 操作按鈕（需要顯示進度，所以會跟著 completedCount 更新）
            _ExtractionActionsSection(onStart: _startBatchProcessing),

            // 處理進度摘要（跟著 items 更新）
            const _ExtractionSummarySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors, int maxConcurrency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Realsense Pose Extractor',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '將 bag 檔案轉換為姿態資料並寫入資料庫，以供復健分析使用。支援多檔案選擇，最多同時處理 $maxConcurrency 個檔案。',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

}

class _ExtractionFilesSection extends ConsumerWidget {
  const _ExtractionFilesSection({
    required this.onPickFiles,
    required this.onPickLocalFiles,
    required this.maxConcurrency,
  });

  final Future<void> Function() onPickFiles;
  final Future<void> Function() onPickLocalFiles;
  final int maxConcurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchNotifier = ref.read(batchExtractionControllerProvider.notifier);
    final isProcessing = ref.watch(
      batchExtractionControllerProvider.select((s) => s.isProcessing),
    );
    final itemCount = ref.watch(
      batchExtractionControllerProvider.select((s) => s.items.length),
    );
    final hasFiles = itemCount > 0;
    final env = PlatformEnv.current();
    final canPickLocal = !env.isWeb && env.isDesktop;

    final serverTitle = hasFiles ? '繼續新增（伺服器）' : '從伺服器挑選 Bag 檔案';
    final serverSubtitle =
        '從伺服器清單挑選，不需上傳；最多同時處理 $maxConcurrency 個檔案';
    const localTitle = '從本機挑選 Bag 檔案（桌面）';
    const localSubtitle = '從本機讀取 .bag；會以 bag_path 送出';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final maxWidth = constraints.maxWidth;
            // 桌面且寬螢幕時顯示雙欄；其餘情境使用單欄撐滿。
            final useTwoColumns = canPickLocal && maxWidth >= 900;
            final cardWidth = useTwoColumns ? (maxWidth - spacing) / 2 : maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: BagSourceCard(
                    title: serverTitle,
                    subtitle: serverSubtitle,
                    icon: Icons.cloud_download_outlined,
                    onTap: isProcessing ? null : onPickFiles,
                  ),
                ),
                if (canPickLocal)
                  SizedBox(
                    width: cardWidth,
                    child: BagSourceCard(
                      title: localTitle,
                      subtitle: localSubtitle,
                      icon: Icons.folder_open_outlined,
                      onTap: isProcessing ? null : onPickLocalFiles,
                    ),
                  ),
              ],
            );
          },
        ),
        if (hasFiles) ...[
          const SizedBox(height: 16),
          FileExtractionList(
            isProcessing: isProcessing,
            onRemove: batchNotifier.removeItem,
            onSessionNameChanged: batchNotifier.setSessionName,
            onRetry: (key) => batchNotifier.retryItem(
              key: key,
              config: ref.read(extractConfigProvider),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExtractionConfigSection extends ConsumerWidget {
  const _ExtractionConfigSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final config = ref.watch(extractConfigProvider);
    final configNotifier = ref.read(extractConfigProvider.notifier);
    final isProcessing = ref.watch(
      batchExtractionControllerProvider.select((s) => s.isProcessing),
    );
    final textTheme = context.textTheme;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // 覆蓋既有 session 開關
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: context.scaffoldBackgroundColor,
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch.adaptive(
                    value: config.force,
                    onChanged: isProcessing ? null : configNotifier.setForce,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '覆蓋既有 session',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '若 session 已存在，啟用後會重新處理。',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // 校準姿勢開關
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: context.scaffoldBackgroundColor,
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch.adaptive(
                    value: config.calibratePose,
                    onChanged: isProcessing ? null : configNotifier.setCalibratePose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '寫入前自動校準',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '預設啟用，避免姿態偏移；若需原始輸出可關閉。',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // 輸出影片開關
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: context.scaffoldBackgroundColor,
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch.adaptive(
                    value: config.saveVideo,
                    onChanged: isProcessing ? null : configNotifier.setSaveVideo,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '輸出骨架影片',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '預設啟用，產生帶有骨架標註的影片檔。',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // 跳過影格滑桿
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '跳過影格 (skip_frames)',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Slider(
                value: config.skipFrames.toDouble(),
                min: 0,
                max: 12,
                divisions: 12,
                label: config.skipFrames.toString(),
                onChanged: isProcessing
                    ? null
                    : (value) => configNotifier.setSkipFrames(value.round()),
              ),
            ],
          ),
        ),

        // 最大影格數
        SizedBox(
          width: 180,
          child: AppSelect<int>(
            value: config.maxFrames,
            // 常用選項：避免讓使用者手動輸入錯誤值；如需更細緻控制再改成輸入框。
            items: const [300, 600, 900, 1800, 3600, 7200, 10800],
            enabled: !isProcessing,
            tooltip: '最大影格數 (max_frames)',
            itemLabelBuilder: (val) => val.toString(),
            menuWidth: const BoxConstraints(minWidth: 140, maxWidth: 200),
            onChanged: configNotifier.setMaxFrames,
          ),
        ),

        // 模型複雜度
        SizedBox(
          width: 180,
          child: AppSelect<int>(
            value: config.modelComplexity,
            items: const [0, 1, 2],
            tooltip: '模型複雜度',
            itemLabelBuilder: (val) => switch (val) {
              0 => '0 - Fast',
              1 => '1 - Balanced',
              2 => '2 - Accurate',
              _ => '$val',
            },
            menuWidth: const BoxConstraints(minWidth: 140, maxWidth: 200),
            enabled: !isProcessing,
            onChanged: configNotifier.setModelComplexity,
          ),
        ),

        // 最大並行處理數
        SizedBox(
          width: 180,
          child: AppSelect<int>(
            value: config.maxConcurrency,
            items: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            tooltip: '最大並行處理數',
            itemLabelBuilder: (val) => '$val 個同時',
            menuWidth: const BoxConstraints(minWidth: 140, maxWidth: 200),
            enabled: !isProcessing,
            onChanged: configNotifier.setMaxConcurrency,
          ),
        ),

        // 偵測信心滑桿
        SizedBox(
          width: 260,
          child: ConfidenceSlider(
            label: '偵測信心 (min_detection)',
            value: config.minDetectionConfidence,
            onChanged: isProcessing ? null : configNotifier.setMinDetectionConfidence,
          ),
        ),

        // 追蹤信心滑桿
        SizedBox(
          width: 260,
          child: ConfidenceSlider(
            label: '追蹤信心 (min_tracking)',
            value: config.minTrackingConfidence,
            onChanged: isProcessing ? null : configNotifier.setMinTrackingConfidence,
          ),
        ),
      ],
    );
  }
}

class _ExtractionActionsSection extends ConsumerWidget {
  const _ExtractionActionsSection({required this.onStart});

  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final configNotifier = ref.read(extractConfigProvider.notifier);
    final batchNotifier = ref.read(batchExtractionControllerProvider.notifier);
    final isProcessing = ref.watch(
      batchExtractionControllerProvider.select((s) => s.isProcessing),
    );
    final itemCount = ref.watch(
      batchExtractionControllerProvider.select((s) => s.items.length),
    );
    final completedCount = ref.watch(
      batchExtractionControllerProvider.select((s) => s.completedCount),
    );

    final hasFiles = itemCount > 0;

    String label;
    if (isProcessing) {
      label = '處理中 ($completedCount/$itemCount)…';
    } else if (!hasFiles) {
      label = '請選擇檔案';
    } else {
      label = '執行 Extract ($itemCount 個檔案)';
    }

    return Row(
      children: [
        FilledButton.icon(
          onPressed: (!hasFiles || isProcessing) ? null : onStart,
          icon: isProcessing
              ? const RepaintBoundary(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.play_arrow),
          label: Text(label),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: isProcessing ? null : configNotifier.reset,
          style: TextButton.styleFrom(foregroundColor: colors.onSurfaceVariant),
          child: const Text('還原預設參數'),
        ),
        if (hasFiles && !isProcessing) ...[
          const SizedBox(width: 16),
          TextButton(
            onPressed: batchNotifier.clearAll,
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
            ),
            child: const Text('清空檔案'),
          ),
        ],
      ],
    );
  }
}

class _ExtractionSummarySection extends ConsumerWidget {
  const _ExtractionSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(
      batchExtractionControllerProvider.select(
        (s) => s.isProcessing || s.isAllCompleted,
      ),
    );
    if (!show) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(batchExtractionControllerProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ExtractionProcessingSummary(state: state),
    );
  }
}
