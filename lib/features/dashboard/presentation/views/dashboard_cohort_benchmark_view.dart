import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/benchmark_content_body.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/cohort_configuration_section.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/cohort_users_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/delete_cohort_benchmark_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/manage_cohorts/manage_cohorts.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/sticky_tab_bar_delegate.dart';

class DashboardCohortBenchmarkView extends ConsumerStatefulWidget {
  const DashboardCohortBenchmarkView({super.key});

  @override
  ConsumerState<DashboardCohortBenchmarkView> createState() =>
      _DashboardCohortBenchmarkViewState();
}

class _DashboardCohortBenchmarkViewState
    extends ConsumerState<DashboardCohortBenchmarkView> {
  bool _isCalculating = false;
  bool _isDeletingBenchmarks = false;
  String _activeTabId = 'overview';

  late final TextEditingController _sessionNameController;
  CohortBenchmarkCompareResponse? _lastCompareResponse;

  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  @override
  void initState() {
    super.initState();
    // 初始化時從全域 activeSessionProvider 取得目前 session
    final initialSession = ref.read(activeSessionProvider);
    _sessionNameController = TextEditingController(text: initialSession);
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }


  void _toast(
    String message, {
    DashboardToastVariant variant = DashboardToastVariant.info,
  }) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  String _formatCompareError(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) return '比對失敗';
    final lower = message.toLowerCase();
    if (lower.contains('benchmark') && lower.contains('not found')) {
      return '比對失敗：該族群尚未有基準值（請先計算族群基準）';
    }
    return '比對失敗：$message';
  }

  Future<void> _calculateSelected({required bool force}) async {
    final cohortName = ref.read(selectedCohortProvider)?.trim() ?? '';
    if (cohortName.isEmpty) {
      _toast('請先選擇 cohort', variant: DashboardToastVariant.warning);
      return;
    }
    if (_isCalculating) return;

    setState(() => _isCalculating = true);
    try {
      final result = await _repo.calculateCohortBenchmark(
        cohortName: cohortName,
        forceRecalculate: force,
      );
      if (!mounted) return;
      _toast(
        force ? '已重新計算：${result.cohortName}' : '已取得基準值：${result.cohortName}',
        variant: DashboardToastVariant.success,
      );
      ref.invalidate(cohortBenchmarkListProvider);
      ref.invalidate(cohortBenchmarkDetailProvider(cohortName));
    } catch (e) {
      if (!mounted) return;
      _toast('計算失敗：$e', variant: DashboardToastVariant.danger);
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  Future<void> _deleteBenchmark(String cohortName) async {
    final name = cohortName.trim();
    if (name.isEmpty || _isDeletingBenchmarks) return;

    final confirmed = await DeleteCohortBenchmarkDialog.show(
      context,
      cohortName: name,
    );
    if (!mounted || confirmed != true) return;

    setState(() => _isDeletingBenchmarks = true);
    try {
      final resp = await _repo.deleteCohortBenchmarks(cohortNames: [name]);
      if (!mounted) return;
      final deleted = resp.deleted.contains(name);
      _toast(
        deleted ? '已刪除基準值：$name' : '刪除失敗：$name',
        variant: deleted
            ? DashboardToastVariant.success
            : DashboardToastVariant.danger,
      );
      // 如果刪除的是目前選擇的 cohort，清除選擇
      if (ref.read(selectedCohortProvider) == name) {
        ref.read(selectedCohortProvider.notifier).select(null);
      }
      ref.invalidate(cohortBenchmarkListProvider);
    } catch (e) {
      if (!mounted) return;
      _toast('刪除失敗：$e', variant: DashboardToastVariant.danger);
    } finally {
      if (mounted) setState(() => _isDeletingBenchmarks = false);
    }
  }

  Future<void> _browseSessions() async {
    final selected = await SessionPickerDialog.show(context);
    if (!mounted || selected == null || selected.trim().isEmpty) return;
    final sessionName = selected.trim();
    _sessionNameController.text = sessionName;
    // 同步更新全域 activeSessionProvider
    ref.read(activeSessionProvider.notifier).setSession(sessionName);
  }

  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _toast('已複製 $label', variant: DashboardToastVariant.success);
  }

  Future<void> _showCohortUsersDialog(String cohortName) async {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => CohortUsersDialog(cohortName: cohortName),
      ),
    );
  }

  Future<void> _submitCompare({String? cohortName}) async {
    final sessionName = _sessionNameController.text.trim();
    if (sessionName.isEmpty) {
      _toast('請輸入 session_name', variant: DashboardToastVariant.warning);
      return;
    }

    final resolvedCohort = cohortName?.trim() ?? '';
    if (resolvedCohort.isEmpty) {
      _toast('請先選擇 cohort（用於比對）', variant: DashboardToastVariant.warning);
      return;
    }

    await ref
        .read(cohortBenchmarkCompareControllerProvider.notifier)
        .submit(sessionName: sessionName, cohortName: resolvedCohort);
  }

  void _showManageCohortsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => ManageCohortsDialog(
        onDeleteBenchmark: _deleteBenchmark,
        onShowCohortUsers: _showCohortUsersDialog,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 1000;

    final compareAsync = ref.watch(cohortBenchmarkCompareControllerProvider);

    // 監聽全域 session 變化，同步更新本地 controller
    ref.listen<String>(activeSessionProvider, (previous, next) {
      if (_sessionNameController.text != next) {
        _sessionNameController.text = next;
      }
    });

    // compare API 失敗時：只跳通知，不用錯誤卡片蓋住整個內容
    ref.listen<AsyncValue<CohortBenchmarkCompareResponse?>>(
      cohortBenchmarkCompareControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (data) {
            if (data == null) return;
            if (!mounted) return;
            setState(() => _lastCompareResponse = data);
          },
          error: (error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _toast(
                _formatCompareError(error),
                variant: DashboardToastVariant.danger,
              );
            });
          },
        );
      },
    );

    final selectedCohortName = ref.watch(selectedCohortProvider)?.trim();
    final hasSelectedCohort =
        selectedCohortName != null && selectedCohortName.isNotEmpty;

    final compareData =
        compareAsync.maybeWhen(data: (d) => d, orElse: () => null) ??
        _lastCompareResponse;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '族群基準分析',
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '設定分析族群，選取 Session，取得您與族群的百分位比較。',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CohortConfigurationSection(
                    selectedCohortName: selectedCohortName,
                    sessionController: _sessionNameController,
                    isCalculating: _isCalculating,
                    compareIsLoading: compareAsync.isLoading,
                    hasSelectedCohort: hasSelectedCohort,
                    onCohortChanged: (val) =>
                        ref.read(selectedCohortProvider.notifier).select(val),
                    onCalculate: (force) => _calculateSelected(force: force),
                    onCompare: () =>
                        _submitCompare(cohortName: selectedCohortName),
                    onBrowseSessions: _browseSessions,
                    onManageCohorts: _showManageCohortsDialog,
                  ),
                ],
              ),
            ),
          ),
          if (compareData != null) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: StickyTabBarDelegate(
                  activeTabId: _activeTabId,
                  onTabSelected: (id) => setState(() => _activeTabId = id),
                  tabs: const [
                    ('overview', '總覽'),
                    ('lap_time', 'Lap Time'),
                    ('gait', 'Gait'),
                    ('speed_distance', 'Speed'),
                    ('turn', 'Turn'),
                    ('functional', '功能評估'),
                  ],
                  colors: colors,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadataControls(context, colors, compareData),
                    const SizedBox(height: 24),
                    BenchmarkContentBody(
                      tabId: _activeTabId,
                      data: compareData,
                      isWide: isWide,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ] else if (compareAsync.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  '請先設定並開始比對',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildMetadataControls(
    BuildContext context,
    ColorScheme colors,
    CohortBenchmarkCompareResponse compareData,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InfoChip(
          icon: Icons.person_outline,
          label: 'User',
          value: compareData.userCode,
          onCopy: () => _copyToClipboard('User Code', compareData.userCode),
        ),
        _InfoChip(
          icon: Icons.folder_open,
          label: 'Session',
          value: compareData.sessionName,
          onCopy: () => _copyToClipboard('Session', compareData.sessionName),
        ),
        _InfoChip(
          icon: Icons.groups_outlined,
          label: 'Cohort',
          value: compareData.cohortName,
          onCopy: () => _copyToClipboard('Cohort', compareData.cohortName),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.outlineVariant),
          color: colors.surface.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.copy_rounded, size: 12, color: colors.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}
