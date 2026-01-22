import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';

const String _kCohortBenchmarkListRequestId = 'cohort_benchmark_list';
const String _kCohortBenchmarkDetailRequestId = 'cohort_benchmark_detail';

/// 儲存目前選擇的 cohort 名稱，切換頁面時保持狀態。
class SelectedCohortNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? cohortName) => state = cohortName;
}

final selectedCohortProvider =
    NotifierProvider<SelectedCohortNotifier, String?>(SelectedCohortNotifier.new);

/// 列出所有已計算完成的 cohorts。
final cohortBenchmarkListProvider =
    FutureProvider.autoDispose<CohortBenchmarkListResponse>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  const fingerprint = 1;
  return fetchWithFailureGate(
    ref,
    requestId: _kCohortBenchmarkListRequestId,
    fingerprint: fingerprint,
    fetch: repo.fetchCohortBenchmarkList,
  );
});

/// 取得指定 cohort 的基準值 detail（已計算）。
final cohortBenchmarkDetailProvider = FutureProvider.autoDispose
    .family<CohortBenchmarkDetail?, String>((ref, cohortName) async {
  final name = cohortName.trim();
  if (name.isEmpty) {
    throw ArgumentError.value(cohortName, 'cohortName', '不可為空');
  }
  final repo = ref.watch(dashboardRepositoryProvider);
  final fingerprint = name.hashCode;
  return fetchWithFailureGate(
    ref,
    requestId: '$_kCohortBenchmarkDetailRequestId:$name',
    fingerprint: fingerprint,
    fetch: () => repo.fetchCohortBenchmarkDetail(cohortName: name),
  );
});

/// 供 UI 主動觸發 compare。
class CohortBenchmarkCompareController
    extends Notifier<AsyncValue<CohortBenchmarkCompareResponse?>> {
  DashboardRepository get _repo => ref.watch(dashboardRepositoryProvider);

  @override
  AsyncValue<CohortBenchmarkCompareResponse?> build() {
    return const AsyncData<CohortBenchmarkCompareResponse?>(null);
  }

  Future<void> submit({
    required String sessionName,
    required String cohortName,
  }) async {
    state = const AsyncLoading<CohortBenchmarkCompareResponse?>();
    try {
      final response = await _repo.compareCohortBenchmark(
        sessionName: sessionName,
        cohortName: cohortName,
      );
      if (!ref.mounted) return;
      state = AsyncData(response);
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncError(error, stackTrace);
    }
  }

  void reset() => state = const AsyncData<CohortBenchmarkCompareResponse?>(null);
}

final cohortBenchmarkCompareControllerProvider = NotifierProvider<
    CohortBenchmarkCompareController,
    AsyncValue<CohortBenchmarkCompareResponse?>>(
  CohortBenchmarkCompareController.new,
);


