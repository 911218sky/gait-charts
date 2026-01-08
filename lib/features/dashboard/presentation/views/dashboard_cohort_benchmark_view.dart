import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/benchmark_radar.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/cohort_selector_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/delete_cohort_benchmark_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metric_highlight_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metric_status_badge.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:google_fonts/google_fonts.dart';

/// UI 顯示用：選擇要查看哪個位數（或平均值）。
enum CohortBenchmarkCompareBasis { p10, p25, p50, p75, p90, mean }

class DashboardCohortBenchmarkView extends ConsumerStatefulWidget {
  const DashboardCohortBenchmarkView({super.key});

  @override
  ConsumerState<DashboardCohortBenchmarkView> createState() =>
      _DashboardCohortBenchmarkViewState();
}

class _DashboardCohortBenchmarkViewState
    extends ConsumerState<DashboardCohortBenchmarkView> {
  String? _selectedCohortName;
  bool _isCalculating = false;
  bool _isDeletingBenchmarks = false;
  CohortBenchmarkCompareBasis _compareBasis = CohortBenchmarkCompareBasis.p50;
  String _activeTabId = 'overview';

  late final TextEditingController _sessionNameController;

  CohortBenchmarkCompareResponse? _lastCompareResponse;

  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController();
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
    final cohortName = _selectedCohortName?.trim() ?? '';
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
      final resp = await _repo.deleteCohortBenchmarks(
        cohortNames: <String>[name],
      );
      if (!mounted) return;
      final deleted = resp.deleted.contains(name);
      _toast(
        deleted ? '已刪除基準值：$name' : '刪除失敗：$name',
        variant: deleted
            ? DashboardToastVariant.success
            : DashboardToastVariant.danger,
      );
      if (_selectedCohortName == name) {
        setState(() => _selectedCohortName = null);
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
    _sessionNameController.text = selected.trim();
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
        builder: (context) => _CohortUsersDialog(cohortName: cohortName),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    final basisLabel = _compareBasisLabelLong(_compareBasis);

    final compareAsync = ref.watch(cohortBenchmarkCompareControllerProvider);

    // compare API 失敗時：只跳通知，不用錯誤卡片蓋住整個內容。
    // 同時保留上一次成功的比對結果，避免使用者操作被中斷。
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

    final selectedCohortName = _selectedCohortName?.trim();
    final hasSelectedCohort =
        selectedCohortName != null && selectedCohortName.isNotEmpty;

    final compareData =
        compareAsync.maybeWhen(data: (d) => d, orElse: () => null) ??
        _lastCompareResponse;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 0,
            ),
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
                  // Configuration Card
                  _ConfigurationSection(
                    selectedCohortName: _selectedCohortName,
                    sessionController: _sessionNameController,
                    isCalculating: _isCalculating,
                    compareIsLoading: compareAsync.isLoading,
                    hasSelectedCohort: hasSelectedCohort,
                    onCohortChanged: (val) {
                      setState(() => _selectedCohortName = val);
                    },
                    onCalculate: (force) => _calculateSelected(force: force),
                    onCompare: () =>
                        _submitCompare(cohortName: _selectedCohortName),
                    onBrowseSessions: _browseSessions,
                    onManageCohorts: () {
                      // 彈窗顯示管理 cohorts 的界面
                      _showManageCohortsDialog(context, ref);
                    },
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
                    // Metadata & Controls
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoChip(
                          icon: Icons.person_outline,
                          label: 'User',
                          value: compareData.userCode,
                          onCopy: () => _copyToClipboard(
                            'User Code',
                            compareData.userCode,
                          ),
                        ),
                        _InfoChip(
                          icon: Icons.folder_open,
                          label: 'Session',
                          value: compareData.sessionName,
                          onCopy: () => _copyToClipboard(
                            'Session',
                            compareData.sessionName,
                          ),
                        ),
                        _InfoChip(
                          icon: Icons.groups_outlined,
                          label: 'Cohort',
                          value: compareData.cohortName,
                          onCopy: () => _copyToClipboard(
                            'Cohort',
                            compareData.cohortName,
                          ),
                        ),
                        Container(
                          height: 20,
                          width: 1,
                          color: colors.outlineVariant,
                        ),
                        Text(
                          '顯示位數',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        SegmentedButton<CohortBenchmarkCompareBasis>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: CohortBenchmarkCompareBasis.p25,
                              label: Text('P25'),
                            ),
                            ButtonSegment(
                              value: CohortBenchmarkCompareBasis.p50,
                              label: Text('P50'),
                            ),
                            ButtonSegment(
                              value: CohortBenchmarkCompareBasis.p75,
                              label: Text('P75'),
                            ),
                            ButtonSegment(
                              value: CohortBenchmarkCompareBasis.mean,
                              label: Text('Mean'),
                            ),
                          ],
                          selected: {_compareBasis},
                          onSelectionChanged: (s) {
                            if (s.isNotEmpty) {
                              setState(() => _compareBasis = s.first);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ContentBody(
                      tabId: _activeTabId,
                      data: compareData,
                      basis: _compareBasis,
                      basisLabel: basisLabel,
                      isWide: isWide,
                    ),
                    const SizedBox(height: 80), // Bottom padding
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

  void _showManageCohortsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ManageCohortsDialog(
        onDeleteBenchmark: _deleteBenchmark,
        onShowCohortUsers: _showCohortUsersDialog,
      ),
    );
  }
}

/// 管理族群 Dialog
class _ManageCohortsDialog extends ConsumerWidget {
  const _ManageCohortsDialog({
    required this.onDeleteBenchmark,
    required this.onShowCohortUsers,
  });

  final void Function(String cohortName) onDeleteBenchmark;
  final void Function(String cohortName) onShowCohortUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final listAsync = ref.watch(cohortBenchmarkListProvider);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '管理族群',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '查看與管理已建立的 Cohort 基準',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: colors.onSurface),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: AsyncRequestView<CohortBenchmarkListResponse>(
                requestId: 'manage_cohorts',
                value: listAsync,
                onRetry: () => ref.invalidate(cohortBenchmarkListProvider),
                dataBuilder: (context, data) {
                  if (data.cohorts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A1A1A)
                                  : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.folder_off_rounded,
                              size: 40,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '尚無族群基準',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '選擇 Cohort 並計算基準後會顯示在這裡',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: data.cohorts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = data.cohorts[index];
                      return _CohortListItem(
                        cohortName: item.cohortName,
                        userCount: item.userCount,
                        sessionCount: item.sessionCount,
                        lapCount: item.lapCount,
                        version: item.version,
                        onTap: () => onShowCohortUsers(item.cohortName),
                        onDelete: () {
                          Navigator.pop(context);
                          onDeleteBenchmark(item.cohortName);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outlineVariant),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('關閉'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cohort 列表項目（卡片風格）
class _CohortListItem extends StatelessWidget {
  const _CohortListItem({
    required this.cohortName,
    required this.userCount,
    required this.sessionCount,
    required this.lapCount,
    required this.version,
    required this.onTap,
    required this.onDelete,
  });

  final String cohortName;
  final int userCount;
  final int sessionCount;
  final int lapCount;
  final int version;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final accentColors = DashboardAccentColors.of(context);

    return Material(
      color: isDark ? const Color(0xFF111111) : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colors.onSurface.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 左側首字母
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    cohortName.isNotEmpty ? cohortName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cohortName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatBadge(
                          icon: Icons.person_outline,
                          label: '$userCount 人',
                          colors: colors,
                          isDark: isDark,
                        ),
                        _StatBadge(
                          icon: Icons.folder_outlined,
                          label: '$sessionCount sessions',
                          colors: colors,
                          isDark: isDark,
                        ),
                        _StatBadge(
                          icon: Icons.directions_walk,
                          label: '$lapCount laps',
                          colors: colors,
                          isDark: isDark,
                        ),
                        _StatBadge(
                          icon: Icons.tag,
                          label: 'v$version',
                          colors: colors,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 刪除按鈕
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: accentColors.danger.withValues(alpha: 0.8),
                  backgroundColor: accentColors.danger.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(40, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: '刪除基準',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 統計標籤
class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.colors,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final ColorScheme colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A1A)
            : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigurationSection extends ConsumerWidget {
  const _ConfigurationSection({
    required this.selectedCohortName,
    required this.sessionController,
    required this.isCalculating,
    required this.compareIsLoading,
    required this.hasSelectedCohort,
    required this.onCohortChanged,
    required this.onCalculate,
    required this.onCompare,
    required this.onBrowseSessions,
    required this.onManageCohorts,
  });

  final String? selectedCohortName;
  final TextEditingController sessionController;
  final bool isCalculating;
  final bool compareIsLoading;
  final bool hasSelectedCohort;
  final ValueChanged<String?> onCohortChanged;
  final void Function(bool force) onCalculate;
  final VoidCallback onCompare;
  final VoidCallback onBrowseSessions;
  final VoidCallback onManageCohorts;

  Future<void> _selectCohort(BuildContext context) async {
    final selected = await CohortSelectorDialog.show(
      context,
      initialSelected: selectedCohortName,
    );
    if (selected != null && selected.trim().isNotEmpty) {
      onCohortChanged(selected.trim());
      // 選擇後自動觸發計算
      onCalculate(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    // 取得選中 cohort 的使用者數量（用於顯示）
    final cohortsAsync = ref.watch(userCohortsProvider(false));
    final selectedCohortStat = cohortsAsync.maybeWhen(
      data: (r) => r.cohorts.firstWhere(
        (c) => c.cohort == selectedCohortName,
        orElse: () => const UserCohortStat(cohort: '', userCount: 0),
      ),
      orElse: () => const UserCohortStat(cohort: '', userCount: 0),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：族群選擇
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '基準族群 (Cohort)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 族群選擇器
                    InkWell(
                      onTap: isCalculating ? null : () => _selectCohort(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF111111)
                              : colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasSelectedCohort
                                ? colors.primary.withValues(alpha: 0.4)
                                : colors.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.groups_rounded,
                                size: 16,
                                color: hasSelectedCohort
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: hasSelectedCohort
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedCohortName!,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.onSurface,
                                          ),
                                        ),
                                        if (selectedCohortStat.userCount > 0)
                                          Text(
                                            '${selectedCohortStat.userCount} 人',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    )
                                  : Text(
                                      '點擊選擇族群...',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                            Icon(
                              Icons.unfold_more_rounded,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 管理 & 重新計算按鈕
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onManageCohorts,
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text('管理'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outlineVariant),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: hasSelectedCohort && !isCalculating
                        ? () => onCalculate(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : colors.surfaceContainerHighest,
                      foregroundColor: colors.onSurface,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF111111)
                          : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      disabledForegroundColor: colors.onSurface.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: isCalculating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('重新計算'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 第二行：Session 輸入
          Row(
            children: [
              Expanded(
                child: SessionAutocompleteField(
                  controller: sessionController,
                  labelText: '比對 Session',
                  hintText: '輸入 session_name',
                  onSubmitted: (_) => onCompare(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onBrowseSessions,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.outlineVariant),
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.list, size: 20),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: compareIsLoading ? null : onCompare,
                icon: compareIsLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, size: 18),
                label: const Text('開始分析'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  StickyTabBarDelegate({
    required this.activeTabId,
    required this.onTabSelected,
    required this.tabs,
    required this.colors,
  });

  final String activeTabId;
  final ValueChanged<String> onTabSelected;
  final List<(String, String)> tabs;
  final ColorScheme colors;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: context.theme.scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isActive = activeTabId == t.$1;
            return InkWell(
              onTap: () => onTabSelected(t.$1),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  border: isActive
                      ? Border.all(color: colors.primary.withValues(alpha: 0.2))
                      : null,
                ),
                child: Text(
                  t.$2,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate oldDelegate) {
    return activeTabId != oldDelegate.activeTabId;
  }
}

class _ContentBody extends StatelessWidget {
  const _ContentBody({
    required this.tabId,
    required this.data,
    required this.basis,
    required this.basisLabel,
    required this.isWide,
  });

  final String tabId;
  final CohortBenchmarkCompareResponse data;
  final CohortBenchmarkCompareBasis basis;
  final String basisLabel;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    switch (tabId) {
      case 'overview':
        return _buildOverview(context);
      case 'lap_time':
        return _buildDetailSection(
          context,
          title: 'Lap Time',
          map: data.lapTime,
          order: _lapTimeOrder,
          labels: _lapTimeLabels,
        );
      case 'gait':
        return _buildDetailSection(
          context,
          title: 'Gait',
          map: data.gait,
          order: _gaitOrder,
          labels: _gaitLabels,
        );
      case 'speed_distance':
        return _buildDetailSection(
          context,
          title: 'Speed & Distance',
          map: data.speedDistance,
          order: _speedOrder,
          labels: _speedLabels,
        );
      case 'turn':
        return _buildDetailSection(
          context,
          title: 'Turn',
          map: data.turn,
          order: _turnOrder,
          labels: _turnLabels,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverview(BuildContext context) {
    // Collect specific charts for overview
    final lapEntries = _buildRadarEntries(
      context,
      'lap_time',
      data.lapTime,
      _lapTimeOrder,
      _lapTimeLabels,
      basis,
    );
    final gaitEntries = _buildRadarEntries(
      context,
      'gait',
      data.gait,
      _gaitOrder,
      _gaitLabels,
      basis,
    );
    final speedEntries = _buildRadarEntries(
      context,
      'speed_distance',
      data.speedDistance,
      _speedOrder,
      _speedLabels,
      basis,
    );

    // 建立重點指標卡片
    final highlightMetrics = _buildHighlightMetrics(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlightMetrics.isNotEmpty) ...[
          Text(
            '重點指標',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800
                  ? 4
                  : constraints.maxWidth > 600
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: highlightMetrics.length,
                itemBuilder: (context, index) => highlightMetrics[index],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
        if (lapEntries.isNotEmpty)
          _OverviewCard(
            title: 'Lap Time',
            entries: lapEntries,
            basisLabel: basisLabel,
            basis: basis,
          ),
        const SizedBox(height: 24),
        if (gaitEntries.isNotEmpty)
          _OverviewCard(
            title: 'Gait',
            entries: gaitEntries,
            basisLabel: basisLabel,
            basis: basis,
          ),
        const SizedBox(height: 24),
        if (speedEntries.isNotEmpty)
          _OverviewCard(
            title: 'Speed',
            entries: speedEntries,
            basisLabel: basisLabel,
            basis: basis,
          ),
      ],
    );
  }

  /// 建立重點指標卡片列表。
  List<Widget> _buildHighlightMetrics(BuildContext context) {
    final highlights = <Widget>[];

    // 速度 (speed_mps)
    final speedComp = data.speedDistance['speed_mps'];
    if (speedComp != null) {
      final userV = _userValueForBasis(speedComp, basis);
      final pct = _percentilePositionForBasis(speedComp, basis);
      final perfLabel = _betterWorseLabel(
        group: 'speed_distance',
        metricKey: 'speed_mps',
        status: speedComp.status,
      );
      final perfVariant = _performanceVariant(perfLabel);
      final supportDiff = _supportDiffLabelP50(
        group: 'speed_distance',
        metricKey: 'speed_mps',
        c: speedComp,
      );

      highlights.add(
        MetricHighlightCard(
          label: '速度',
          value: userV.toStringAsFixed(2),
          unit: 'm/s',
          status: speedComp.status,
          performanceLabel: perfLabel,
          performanceVariant: perfVariant,
          percentile: pct,
          subtitle: supportDiff,
        ),
      );
    }

    // 單圈總時間 (dur_total)
    final durTotalComp = data.lapTime['dur_total'];
    if (durTotalComp != null) {
      final userV = _userValueForBasis(durTotalComp, basis);
      final pct = _percentilePositionForBasis(durTotalComp, basis);
      final perfLabel = _betterWorseLabel(
        group: 'lap_time',
        metricKey: 'dur_total',
        status: durTotalComp.status,
      );
      final perfVariant = _performanceVariant(perfLabel);
      final supportDiff = _supportDiffLabelP50(
        group: 'lap_time',
        metricKey: 'dur_total',
        c: durTotalComp,
      );

      highlights.add(
        MetricHighlightCard(
          label: '單圈總時間',
          value: userV.toStringAsFixed(2),
          unit: 's',
          status: durTotalComp.status,
          performanceLabel: perfLabel,
          performanceVariant: perfVariant,
          percentile: pct,
          subtitle: supportDiff,
        ),
      );
    }

    // 步頻 (spm)
    final spmComp = data.gait['spm'];
    if (spmComp != null) {
      final userV = _userValueForBasis(spmComp, basis);
      final pct = _percentilePositionForBasis(spmComp, basis);

      highlights.add(
        MetricHighlightCard(
          label: '步頻',
          value: userV.toStringAsFixed(1),
          unit: 'steps/min',
          status: spmComp.status,
          percentile: pct,
        ),
      );
    }

    // 平均步長 (mean_step_len)
    final stepLenComp = data.gait['mean_step_len'];
    if (stepLenComp != null) {
      final userV = _userValueForBasis(stepLenComp, basis);
      final pct = _percentilePositionForBasis(stepLenComp, basis);

      highlights.add(
        MetricHighlightCard(
          label: '平均步長',
          value: userV.toStringAsFixed(3),
          unit: 'm',
          status: stepLenComp.status,
          percentile: pct,
        ),
      );
    }

    return highlights;
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required Map<String, MetricComparison> map,
    required List<String> order,
    required Map<String, String> labels,
  }) {
    final entries = _buildRadarEntries(
      context,
      title,
      map,
      order,
      labels,
      basis,
    );
    final items = _buildMetricItems(map, order: order, labelMap: labels);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entries.isNotEmpty)
          BenchmarkRadar(
            title: title,
            subtitle:
                '雷達圖：使用者${_compareBasisLabelShort(basis)}在族群中的百分位 · 數值顯示：$basisLabel',
            entries: entries,
            height: 320,
          ),
        const SizedBox(height: 32),
        _MetricGroupList(title: '$title Metrics', items: items, basis: basis),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.entries,
    required this.basisLabel,
    required this.basis,
  });
  final String title;
  final List<BenchmarkRadarEntry> entries;
  final String basisLabel;
  final CohortBenchmarkCompareBasis basis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BenchmarkRadar(
            title: title,
            subtitle:
                '雷達圖：使用者${_compareBasisLabelShort(basis)}在族群中的百分位 · 數值顯示：$basisLabel',
            entries: entries,
            height: 300,
          ),
        ],
      ),
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
              Icon(
                Icons.copy_rounded,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow {
  const _MetricRow({
    required this.key,
    required this.label,
    required this.comparison,
  });

  final String key;
  final String label;
  final MetricComparison comparison;
}

class _MetricGroupList extends StatelessWidget {
  const _MetricGroupList({
    required this.title,
    required this.items,
    required this.basis,
  });

  final String title;
  final List<_MetricRow> items;
  final CohortBenchmarkCompareBasis basis;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final palette = DashboardBenchmarkCompareColors.of(context);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    Color statusColor(MetricComparisonStatus status) => switch (status) {
      MetricComparisonStatus.belowNormal => palette.lower,
      MetricComparisonStatus.aboveNormal => palette.higher,
      MetricComparisonStatus.normal => palette.inRange,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.85 : 1),
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: isDark ? 0.9 : 1),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final c = item.comparison;
              final userV = _userValueForBasis(c, basis);
              final benchV = _benchmarkValueForBasis(c, basis);
              final status = c.status;
              final pct = _percentilePositionForBasis(c, basis);
              final diffPct = _diffPctForBasis(c, basis);
              final diffText = diffPct == null
                  ? ''
                  : ' · 差異=${diffPct.toStringAsFixed(2)}%';
              final betterWorse = _betterWorseLabel(
                group: title,
                metricKey: item.key,
                status: status,
              );
              final supportDiff = _supportDiffLabelP50(
                group: title,
                metricKey: item.key,
                c: c,
              );
              final supportDiffColor = _supportDiffColorP50(
                context: context,
                group: title,
                metricKey: item.key,
                c: c,
              );
              final subtitle =
                  '個人${_compareBasisLabelShort(basis)}=${userV.toStringAsFixed(3)}（n=${c.userCount}） · 族群${_compareBasisLabelShort(basis)}=${benchV.toStringAsFixed(3)}（n=${c.benchmarkCount}）$diffText · P25-P75=${c.benchmarkP25.toStringAsFixed(3)}~${c.benchmarkP75.toStringAsFixed(3)}';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              MetricStatusBadge(
                                status: status,
                                label: _statusLabelShort(status),
                                size: MetricStatusBadgeSize.small,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (supportDiff != null || betterWorse != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (supportDiff != null)
                                  Text(
                                    supportDiff,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              supportDiffColor ??
                                              colors.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                  ),
                                if (betterWorse != null)
                                  MetricPerformanceBadge(
                                    label: betterWorse,
                                    variant: _performanceVariant(betterWorse),
                                    size: MetricStatusBadgeSize.small,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

List<_MetricRow> _buildMetricItems(
  Map<String, MetricComparison> map, {
  required List<String> order,
  required Map<String, String> labelMap,
}) {
  final result = <_MetricRow>[];
  final seen = <String>{};
  for (final key in order) {
    final comp = map[key];
    if (comp == null) continue;
    seen.add(key);
    result.add(
      _MetricRow(key: key, label: labelMap[key] ?? key, comparison: comp),
    );
  }
  for (final entry in map.entries) {
    if (seen.contains(entry.key)) continue;
    result.add(
      _MetricRow(
        key: entry.key,
        label: labelMap[entry.key] ?? entry.key,
        comparison: entry.value,
      ),
    );
  }
  return result;
}

List<BenchmarkRadarEntry> _buildRadarEntries(
  BuildContext context,
  String title, // added title parameter manually
  Map<String, MetricComparison> map,
  List<String> order,
  Map<String, String> labelMap,
  CohortBenchmarkCompareBasis basis,
) {
  final palette = DashboardBenchmarkCompareColors.of(context);
  final rows = _buildMetricItems(map, order: order, labelMap: labelMap);
  return rows
      .map((row) {
        final c = row.comparison;
        final userV = _userValueForBasis(c, basis);
        final benchV = _benchmarkValueForBasis(c, basis);
        final status = c.status;
        final color = switch (status) {
          MetricComparisonStatus.belowNormal => palette.lower,
          MetricComparisonStatus.aboveNormal => palette.higher,
          MetricComparisonStatus.normal => palette.inRange,
        };
        final diffPct = _diffPctForBasis(c, basis);
        final diffText = diffPct == null
            ? ''
            : ' · 差異=${diffPct.toStringAsFixed(2)}%';
        return BenchmarkRadarEntry(
          key: '$title.${row.key}',
          label: row.label,
          percentile01: (_percentilePositionForBasis(c, basis) / 100).clamp(
            0.0,
            1.0,
          ),
          valueText:
              '個人${_compareBasisLabelShort(basis)}=${userV.toStringAsFixed(3)}（n=${c.userCount}） · 族群${_compareBasisLabelShort(basis)}=${benchV.toStringAsFixed(3)}（n=${c.benchmarkCount}）$diffText · 族群P25=${c.benchmarkP25.toStringAsFixed(3)} · P50=${c.benchmarkP50.toStringAsFixed(3)} · P75=${c.benchmarkP75.toStringAsFixed(3)}',
          status: status,
          color: color,
        );
      })
      .toList(growable: false);
}

String _compareBasisLabelShort(CohortBenchmarkCompareBasis basis) =>
    switch (basis) {
      CohortBenchmarkCompareBasis.p10 => 'P10',
      CohortBenchmarkCompareBasis.p25 => 'P25',
      CohortBenchmarkCompareBasis.p50 => 'P50',
      CohortBenchmarkCompareBasis.p75 => 'P75',
      CohortBenchmarkCompareBasis.p90 => 'P90',
      CohortBenchmarkCompareBasis.mean => 'Mean',
    };

String _compareBasisLabelLong(CohortBenchmarkCompareBasis basis) =>
    switch (basis) {
      CohortBenchmarkCompareBasis.p10 => 'P10',
      CohortBenchmarkCompareBasis.p25 => 'P25',
      CohortBenchmarkCompareBasis.p50 => 'P50（中位數）',
      CohortBenchmarkCompareBasis.p75 => 'P75',
      CohortBenchmarkCompareBasis.p90 => 'P90',
      CohortBenchmarkCompareBasis.mean => 'Mean（平均）',
    };

double _userValueForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) => switch (basis) {
  CohortBenchmarkCompareBasis.p10 => c.userP10,
  CohortBenchmarkCompareBasis.p25 => c.userP25,
  CohortBenchmarkCompareBasis.p50 => c.userP50,
  CohortBenchmarkCompareBasis.p75 => c.userP75,
  CohortBenchmarkCompareBasis.p90 => c.userP90,
  CohortBenchmarkCompareBasis.mean => c.userMean,
};

double _benchmarkValueForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) => switch (basis) {
  CohortBenchmarkCompareBasis.p10 => c.benchmarkP10,
  CohortBenchmarkCompareBasis.p25 => c.benchmarkP25,
  CohortBenchmarkCompareBasis.p50 => c.benchmarkP50,
  CohortBenchmarkCompareBasis.p75 => c.benchmarkP75,
  CohortBenchmarkCompareBasis.p90 => c.benchmarkP90,
  CohortBenchmarkCompareBasis.mean => c.benchmarkMean,
};

double _percentilePositionForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) {
  final d = c.diff;
  final v = switch (basis) {
    CohortBenchmarkCompareBasis.p10 => d?.p10PercentilePosition,
    CohortBenchmarkCompareBasis.p25 => d?.p25PercentilePosition,
    CohortBenchmarkCompareBasis.p50 =>
      (d?.p50PercentilePosition ?? c.percentilePosition),
    CohortBenchmarkCompareBasis.p75 => d?.p75PercentilePosition,
    CohortBenchmarkCompareBasis.p90 => d?.p90PercentilePosition,
    CohortBenchmarkCompareBasis.mean => d?.meanPercentilePosition,
  };
  return (v ?? c.percentilePosition).clamp(0.0, 100.0);
}

double? _diffPctForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) {
  final d = c.diff;
  if (d == null) return null;
  return switch (basis) {
    CohortBenchmarkCompareBasis.p10 => d.p10DiffPct,
    CohortBenchmarkCompareBasis.p25 => d.p25DiffPct,
    CohortBenchmarkCompareBasis.p50 => d.p50DiffPct,
    CohortBenchmarkCompareBasis.p75 => d.p75DiffPct,
    CohortBenchmarkCompareBasis.p90 => d.p90DiffPct,
    CohortBenchmarkCompareBasis.mean => d.meanDiffPct,
  };
}

enum _MetricBetterDirection { lowerIsBetter, higherIsBetter, unknown }

_MetricBetterDirection _betterDirectionForMetric({
  required String group,
  required String metricKey,
}) {
  // lap_time：時間越短通常越好
  if (group == 'lap_time') return _MetricBetterDirection.lowerIsBetter;

  // speed_distance：速度越快通常越好
  if (group == 'speed_distance' && metricKey == 'speed_mps') {
    return _MetricBetterDirection.higherIsBetter;
  }

  // 其他指標（步態比例、路徑距離、轉向角度等）不同族群/情境下不一定能用「越大越好」簡化。
  return _MetricBetterDirection.unknown;
}

String? _betterWorseLabel({
  required String group,
  required String metricKey,
  required MetricComparisonStatus status,
}) {
  final dir = _betterDirectionForMetric(group: group, metricKey: metricKey);
  if (dir == _MetricBetterDirection.unknown) return null;

  if (status == MetricComparisonStatus.normal) return '正常';

  final isBetter = switch (dir) {
    _MetricBetterDirection.lowerIsBetter =>
      status == MetricComparisonStatus.belowNormal,
    _MetricBetterDirection.higherIsBetter =>
      status == MetricComparisonStatus.aboveNormal,
    _MetricBetterDirection.unknown => false,
  };
  return isBetter ? '較佳' : '較差';
}

/// 佐百分比：以 `diff.p50_diff_pct` 表示「比族群中位數快/慢 X%」。
///
/// 注意：diff 的正負意義取決於指標方向：
/// - lowerIsBetter（例如時間）：diff>0 表示「更慢（較差）」；diff<0 表示「更快（較佳）」
/// - higherIsBetter（例如速度）：diff>0 表示「更快（較佳）」；diff<0 表示「更慢（較差）」
String? _supportDiffLabelP50({
  required String group,
  required String metricKey,
  required MetricComparison c,
}) {
  final d = c.diff;
  if (d == null) return null;
  final diffPct = d.p50DiffPct;
  if (!diffPct.isFinite) return null;

  final dir = _betterDirectionForMetric(group: group, metricKey: metricKey);
  final abs = diffPct.abs();

  if (abs < 0.0005) return '比中位數 持平';

  String verb;
  switch (dir) {
    case _MetricBetterDirection.lowerIsBetter:
      verb = diffPct > 0 ? '慢' : '快';
      break;
    case _MetricBetterDirection.higherIsBetter:
      verb = diffPct > 0 ? '快' : '慢';
      break;
    case _MetricBetterDirection.unknown:
      return '比中位數 ${diffPct >= 0 ? '+' : '-'}${abs.toStringAsFixed(1)}%';
  }
  return '比中位數 $verb ${abs.toStringAsFixed(1)}%';
}

Color? _supportDiffColorP50({
  required BuildContext context,
  required String group,
  required String metricKey,
  required MetricComparison c,
}) {
  final d = c.diff;
  if (d == null) return null;
  final diffPct = d.p50DiffPct;
  if (!diffPct.isFinite) return null;
  if (diffPct.abs() < 0.0005) return null;

  final dir = _betterDirectionForMetric(group: group, metricKey: metricKey);
  if (dir == _MetricBetterDirection.unknown) return null;

  final isBetter = switch (dir) {
    _MetricBetterDirection.lowerIsBetter => diffPct < 0,
    _MetricBetterDirection.higherIsBetter => diffPct > 0,
    _MetricBetterDirection.unknown => false,
  };
  final colors = context.colorScheme;
  return isBetter ? colors.tertiary : colors.error;
}

const List<String> _lapTimeOrder = [
  'dur_total',
  'dur_stand',
  'dur_to_cone',
  'dur_cone_turn',
  'dur_return',
  'dur_turn_to_sit',
  'dur_sit',
];
const Map<String, String> _lapTimeLabels = {
  'dur_total': '單圈總時間',
  'dur_stand': '起身時間',
  'dur_to_cone': '走向錐子（去程）',
  'dur_cone_turn': '錐子轉身',
  'dur_return': '返回（回程）',
  'dur_turn_to_sit': '椅子轉身對位',
  'dur_sit': '坐下時間',
};

const List<String> _gaitOrder = [
  'spm',
  'mean_step_len',
  'l_swing_pct',
  'r_swing_pct',
  'l_stance_s',
  'r_stance_s',
];
const Map<String, String> _gaitLabels = {
  'spm': '步頻',
  'mean_step_len': '平均步長',
  'l_swing_pct': '左擺動期%',
  'r_swing_pct': '右擺動期%',
  'l_stance_s': '左支撐期(s)',
  'r_stance_s': '右支撐期(s)',
};

const List<String> _speedOrder = [
  'speed_mps',
  'dist_lap_path_m',
  'dist_outbound_m',
  'dist_return_m',
  'dist_cone_turn_m',
];
const Map<String, String> _speedLabels = {
  'speed_mps': '速度(m/s)',
  'dist_lap_path_m': '單圈路徑長(m)',
  'dist_outbound_m': '去程距離(m)',
  'dist_return_m': '回程距離(m)',
  'dist_cone_turn_m': '錐子轉身距離(m)',
};

const List<String> _turnOrder = [
  'delta_theta_cone_deg',
  'delta_theta_chair_deg',
];
const Map<String, String> _turnLabels = {
  'delta_theta_cone_deg': '錐子轉身角度(°)',
  'delta_theta_chair_deg': '椅子轉身角度(°)',
};

/// 狀態標籤簡短版本。
String _statusLabelShort(MetricComparisonStatus status) => switch (status) {
      MetricComparisonStatus.normal => '正常',
      MetricComparisonStatus.belowNormal => '偏低',
      MetricComparisonStatus.aboveNormal => '偏高',
    };

/// 將表現標籤轉換為 variant。
MetricPerformanceVariant _performanceVariant(String? label) {
  if (label == null) return MetricPerformanceVariant.normal;
  return switch (label) {
    '較佳' => MetricPerformanceVariant.better,
    '較差' => MetricPerformanceVariant.worse,
    '正常' => MetricPerformanceVariant.normal,
    _ => MetricPerformanceVariant.normal,
  };
}

class _CohortUsersDialog extends ConsumerWidget {
  const _CohortUsersDialog({required this.cohortName});

  final String cohortName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final repo = ref.read(dashboardRepositoryProvider);

    return Dialog(
      backgroundColor: colors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<CohortUsersResponse>(
            future: repo.fetchCohortUsers(
              request: CohortUsersRequest(cohortNames: [cohortName]),
            ),
            builder: (context, snapshot) {
              final title = Row(
                children: [
                  Expanded(
                    child: Text(
                      'user_codes · $cohortName',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.navigator.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              );

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator(value: 0.25)),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    Text(
                      '載入失敗：${snapshot.error}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.navigator.pop(),
                          child: const Text('關閉'),
                        ),
                      ],
                    ),
                  ],
                );
              }

              final data = snapshot.data;
              final codes = data?.userCodes ?? const <String>[];
              final combined = codes.join('\n');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 8),
                  Text(
                    'count=${data?.count ?? codes.length}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                        color: colors.surfaceContainerLow,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          combined.isEmpty ? '（無）' : combined,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: combined.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: combined),
                                );
                                if (context.mounted) {
                                  DashboardToast.show(
                                    context,
                                    message: '已複製 user_codes（${codes.length}）',
                                    variant: DashboardToastVariant.success,
                                  );
                                }
                              },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('複製全部'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.navigator.pop(),
                        child: const Text('關閉'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
