import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';

/// Cohort Benchmark API：
/// - list / users / calculate / get / compare
class CohortBenchmarkApiService {
  CohortBenchmarkApiService(this._dio);

  final Dio _dio;

  /// Base endpoint：`/cohort-benchmark`（baseUrl 已包含 `/api/v1`）。
  static const _kEndpoint = '/cohort-benchmark';

  static const _listEndpoint = '$_kEndpoint/list';
  static const _usersEndpoint = '$_kEndpoint/users';
  static const _calculateEndpoint = '$_kEndpoint/calculate';
  static const _compareEndpoint = '$_kEndpoint/compare';
  static const _deleteEndpoint = '$_kEndpoint/delete';

  static String _detailEndpoint(String cohortName) =>
      '$_kEndpoint/${Uri.encodeComponent(cohortName)}';

  Future<CohortBenchmarkListResponse> fetchCohortList() async {
    try {
      final response = await withApiRetry(
        () => _dio.get<Object?>(_listEndpoint),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return CohortBenchmarkListResponse.fromJson(body.cast<String, dynamic>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<CohortUsersResponse> fetchCohortUsers({
    required CohortUsersRequest request,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Object?>(
          _usersEndpoint,
          data: request.toJson(),
        ),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return CohortUsersResponse.fromJson(body.cast<String, dynamic>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 觸發計算 / 或回傳已存在的基準值（依 force_recalculate 決定）。
  Future<CohortBenchmarkDetail> calculateBenchmark({
    required String cohortName,
    bool forceRecalculate = false,
  }) async {
    final name = cohortName.trim();
    if (name.isEmpty) {
      throw ApiException(message: 'cohort_name 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.post<Object?>(
          _calculateEndpoint,
          data: <String, Object?>{
            'cohort_name': name,
            'force_recalculate': forceRecalculate,
          },
        ),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return CohortBenchmarkDetail.fromJson(body.cast<String, dynamic>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<CohortBenchmarkDetail> fetchBenchmarkDetail({
    required String cohortName,
  }) async {
    final name = cohortName.trim();
    if (name.isEmpty) {
      throw ApiException(message: 'cohort_name 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.get<Object?>(_detailEndpoint(name)),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return CohortBenchmarkDetail.fromJson(body.cast<String, dynamic>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<CohortBenchmarkCompareResponse> compare({
    required String sessionName,
    required String cohortName,
  }) async {
    final session = sessionName.trim();
    final cohort = cohortName.trim();
    if (session.isEmpty) {
      throw ApiException(message: 'session_name 不可為空');
    }
    if (cohort.isEmpty) {
      throw ApiException(message: 'cohort_name 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.post<Object?>(
          _compareEndpoint,
          data: <String, Object?>{
            'session_name': session,
            'cohort_name': cohort,
          },
        ),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return CohortBenchmarkCompareResponse.fromJson(body.cast<String, dynamic>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 刪除族群基準值（支援單筆/批量）：`POST /cohort-benchmark/delete`。
  Future<CohortBenchmarkDeleteBatchResponse> deleteBenchmarks({
    required List<String> cohortNames,
  }) async {
    final normalized = cohortNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (normalized.isEmpty) {
      throw ApiException(message: 'cohort_names 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.post<Object?>(
          _deleteEndpoint,
          data: <String, Object?>{'cohort_names': normalized},
        ),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return CohortBenchmarkDeleteBatchResponse.fromJson(
        body.cast<String, dynamic>(),
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

/// Riverpod Provider for [CohortBenchmarkApiService].
final cohortBenchmarkApiServiceProvider = Provider<CohortBenchmarkApiService>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return CohortBenchmarkApiService(dio);
});


