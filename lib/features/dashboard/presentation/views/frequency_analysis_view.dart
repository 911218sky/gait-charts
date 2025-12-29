import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import '../widgets/frequency_analysis/frequency_analysis_header.dart';
import '../widgets/frequency_analysis/multi_fft_section.dart';
import '../widgets/frequency_analysis/spatial_spectrum_section.dart';
import '../widgets/shared/layout/dashboard_page_padding.dart';
import '../widgets/shared/dialogs/session_picker_sheet.dart';

/// 專門呈現 /spatial_spectrum 與 /multi_fft_from_series 的視圖。
class FrequencyAnalysisView extends ConsumerStatefulWidget {
  const FrequencyAnalysisView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  ConsumerState<FrequencyAnalysisView> createState() =>
      _FrequencyAnalysisViewState();
}

class _FrequencyAnalysisViewState extends ConsumerState<FrequencyAnalysisView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLoad() {
    // 「載入頻譜」按鈕視為 retry：清除 failure gate 並強制刷新兩個 provider。
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          'spatial_spectrum',
        );
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          'multi_fft_from_series',
        );
    widget.onLoadSession();
    ref.invalidate(spatialSpectrumProvider);
    ref.invalidate(multiFftSeriesProvider);
  }

  Future<void> _browseSessions(BuildContext context) async {
    final selected = await SessionPickerDialog.show(context);
    if (selected == null || selected.isEmpty || !context.mounted) {
      return;
    }
    widget.sessionController.text = selected;
    _handleLoad();
  }

  @override
  Widget build(BuildContext context) {
    final spatialAsync = ref.watch(spatialSpectrumProvider);
    final multiAsync = ref.watch(multiFftSeriesProvider);
    final spatialFailure = ref.watch(requestFailureProvider('spatial_spectrum'));
    final multiFailure = ref.watch(
      requestFailureProvider('multi_fft_from_series'),
    );
    final isLoading =
        (spatialAsync.isLoading && spatialFailure == null) ||
        (multiAsync.isLoading && multiFailure == null);

    return ListView(
      controller: _scrollController,
      padding: dashboardPagePadding(context),
      children: [
        FrequencyAnalysisHeader(
          sessionController: widget.sessionController,
          onLoadSession: _handleLoad,
          onBrowseSessions: () => _browseSessions(context),
          isLoading: isLoading,
        ),
        const SizedBox(height: 24),
        SpatialSpectrumSection(data: spatialAsync),
        const SizedBox(height: 24),
        MultiFftSection(data: multiAsync),
      ],
    );
  }
}
