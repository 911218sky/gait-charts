import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/initial_avatar.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cohort 選擇對話框：格子式佈局，顯示族群資訊並需確認才計算基準。
class CohortSelectorDialog extends ConsumerStatefulWidget {
  const CohortSelectorDialog({
    super.key,
    this.initialSelected,
  });

  final String? initialSelected;

  /// 顯示對話框並回傳選擇的 cohort 名稱（若取消則回傳 null）。
  static Future<String?> show(
    BuildContext context, {
    String? initialSelected,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => CohortSelectorDialog(
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  ConsumerState<CohortSelectorDialog> createState() =>
      _CohortSelectorDialogState();
}

class _CohortSelectorDialogState extends ConsumerState<CohortSelectorDialog> {
  String? _selectedCohort;

  @override
  void initState() {
    super.initState();
    _selectedCohort = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final cohortsAsync = ref.watch(userCohortsProvider(false));
    final benchmarkListAsync = ref.watch(cohortBenchmarkListProvider);

    // 建立 cohortName -> CohortBenchmarkListItem 的對照表
    final benchmarkMap = benchmarkListAsync.maybeWhen(
      data: (data) => {
        for (final item in data.cohorts) item.cohortName: item,
      },
      orElse: () => <String, CohortBenchmarkListItem>{},
    );

    return Dialog(
      backgroundColor: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '選擇基準族群',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '選擇一個族群作為比對基準，系統將計算該族群的統計值',
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
              child: cohortsAsync.when(
                data: (data) {
                  final cohorts = [...data.cohorts]
                    ..sort((a, b) => b.userCount.compareTo(a.userCount));

                  if (cohorts.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 160,
                    ),
                    itemCount: cohorts.length,
                    itemBuilder: (context, index) {
                      final stat = cohorts[index];
                      final benchmark = benchmarkMap[stat.cohort];
                      return _CohortGridCard(
                        cohortName: stat.cohort,
                        userCount: stat.userCount,
                        benchmark: benchmark,
                        isSelected: _selectedCohort == stat.cohort,
                        onTap: () {
                          setState(() => _selectedCohort = stat.cohort);
                        },
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 32,
                        color: colors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '載入失敗',
                        style: GoogleFonts.inter(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        error.toString(),
                        style: GoogleFonts.inter(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(userCohortsProvider(false)),
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurface.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedCohort == null
                        ? null
                        : () => Navigator.pop(context, _selectedCohort),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('確認並計算基準'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.onSurface,
                      foregroundColor: colors.surface,
                      disabledBackgroundColor:
                          colors.onSurface.withValues(alpha: 0.1),
                      disabledForegroundColor:
                          colors.onSurface.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.folder_off_rounded,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '尚無可用族群',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請先在使用者管理中設定族群標籤',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cohort Grid 卡片：與 Session 卡片風格一致，顯示更多資訊。
class _CohortGridCard extends StatelessWidget {
  const _CohortGridCard({
    required this.cohortName,
    required this.userCount,
    required this.isSelected,
    required this.onTap,
    this.benchmark,
  });

  final String cohortName;
  final int userCount;
  final bool isSelected;
  final VoidCallback onTap;
  final CohortBenchmarkListItem? benchmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final hasBenchmark = benchmark != null;

    return Material(
      color: context.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colors.primary : colors.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colors.onSurface.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 頂部：首字母 + 已計算標記
              Row(
                children: [
                  InitialAvatar(
                    text: cohortName,
                    size: 36,
                    isSelected: isSelected,
                  ),
                  const Spacer(),
                  if (hasBenchmark)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v${benchmark!.version}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 名稱
              Text(
                cohortName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // 統計資訊
              Text(
                '$userCount 人',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (hasBenchmark) ...[
                const SizedBox(height: 4),
                Text(
                  '${benchmark!.sessionCount} sessions · ${benchmark!.lapCount} laps',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
