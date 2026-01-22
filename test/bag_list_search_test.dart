import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/data/services/analysis/stage_analysis_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/cohort_benchmark/cohort_benchmark_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/extraction/bag_list_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/extraction/extraction_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/sessions/session_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/users/users_api_service.dart';
import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

class _FakeBagListApiService extends BagListApiService {
  _FakeBagListApiService() : super(Dio());

  String? lastQuery;

  @override
  Future<BagFileListResponse> fetchServerBags({
    int page = 1,
    int pageSize = 50,
    bool recursive = true,
    String? query,
  }) async {
    lastQuery = query;
    return const BagFileListResponse(
      total: 0,
      page: 1,
      pageSize: 50,
      totalPages: 0,
      items: [],
    );
  }
}

void main() {
  test('bagListProvider.setQuery 會把 q 帶到 fetchServerBags（server-side search）', () async {
    final fakeBagApi = _FakeBagListApiService();
    final dio = Dio();

    final repo = DashboardRepository(
      cohortBenchmarkApi: CohortBenchmarkApiService(dio),
      stageAnalysisApi: StageAnalysisApiService(dio),
      bagListApi: fakeBagApi,
      extractionApi: ExtractionApiService(dio),
      sessionApi: SessionApiService(dio),
      usersApi: UsersApiService(dio),
    );

    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(bagListProvider.notifier).setQuery('abc', immediate: true);
    expect(fakeBagApi.lastQuery, 'abc');

    await container.read(bagListProvider.notifier).setQuery('   ', immediate: true);
    expect(fakeBagApi.lastQuery, isNull);
  });
}


