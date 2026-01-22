import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';

/// 顯示族群使用者列表的 Dialog
class CohortUsersDialog extends ConsumerWidget {
  const CohortUsersDialog({required this.cohortName, super.key});

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
              final title = _buildTitle(context, colors);

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                );
              }

              if (snapshot.hasError) {
                return _buildError(context, colors, title, snapshot.error);
              }

              final data = snapshot.data;
              final codes = data?.userCodes ?? const <String>[];
              final combined = codes.join('\n');
              return _buildContent(context, colors, title, data, codes, combined);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, ColorScheme colors) {
    return Row(
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
  }


  Widget _buildError(
    BuildContext context,
    ColorScheme colors,
    Widget title,
    Object? error,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 12),
        Text(
          '載入失敗：$error',
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

  Widget _buildContent(
    BuildContext context,
    ColorScheme colors,
    Widget title,
    CohortUsersResponse? data,
    List<String> codes,
    String combined,
  ) {
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
  }
}
