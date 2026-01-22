import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/dashboard/data/services/analysis/stage_analysis_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/cohort_benchmark/cohort_benchmark_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/extraction/bag_list_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/extraction/extraction_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/sessions/session_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/users/users_api_service.dart';
import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 儀表板的資料存取層，封裝 API 呼叫與簡易轉換。
class DashboardRepository {
  DashboardRepository({
    required CohortBenchmarkApiService cohortBenchmarkApi,
    required StageAnalysisApiService stageAnalysisApi,
    required BagListApiService bagListApi,
    required ExtractionApiService extractionApi,
    required SessionApiService sessionApi,
    required UsersApiService usersApi,
  }) : _cohortBenchmarkApi = cohortBenchmarkApi,
       _stageAnalysisApi = stageAnalysisApi,
       _bagListApi = bagListApi,
       _extractionApi = extractionApi,
       _sessionApi = sessionApi,
       _usersApi = usersApi;

  final CohortBenchmarkApiService _cohortBenchmarkApi;
  final StageAnalysisApiService _stageAnalysisApi;
  final BagListApiService _bagListApi;
  final ExtractionApiService _extractionApi;
  final SessionApiService _sessionApi;
  final UsersApiService _usersApi;

  /// 取得步態分期持續時間。
  Future<StageDurationsResponse> fetchStageDurations({
    required String sessionName,
    required StageDurationsConfig config,
  }) {
    return _stageAnalysisApi.fetchStageDurations(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得 per-lap offset 分析。
  Future<PerLapOffsetResponse> fetchPerLapOffset({
    required String sessionName,
    required PerLapOffsetConfig config,
  }) {
    return _stageAnalysisApi.fetchPerLapOffset(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得每分鐘步頻 / 步長柱狀圖資料。
  Future<MinutelyCadenceStepLengthBarsResponse>
  fetchMinutelyCadenceStepLengthBars({
    required String sessionName,
    required MinutelyCadenceStepLengthBarsConfig config,
  }) {
    return _stageAnalysisApi.fetchMinutelyCadenceStepLengthBars(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得左右關節高度差序列。
  Future<YHeightDiffResponse> fetchYHeightDiff({
    required String sessionName,
    required YHeightDiffConfig config,
  }) {
    return _stageAnalysisApi.fetchYHeightDiff(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得 X(Z)/Y(Z) 等空間頻譜。
  Future<SpatialSpectrumResponse> fetchSpatialSpectrum({
    required String sessionName,
    required SpatialSpectrumConfig config,
  }) {
    return _stageAnalysisApi.fetchSpatialSpectrum(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得多關節 FFT 頻譜。
  Future<MultiFftSeriesResponse> fetchMultiFftFromSeries({
    required String sessionName,
    required MultiFftFromSeriesConfig config,
  }) {
    return _stageAnalysisApi.fetchMultiFftFromSeries(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得每圈速度時空熱圖。
  Future<SpeedHeatmapResponse> fetchSpeedHeatmap({
    required String sessionName,
    required SpeedHeatmapConfig config,
  }) {
    return _stageAnalysisApi.fetchSpeedHeatmap(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得每分鐘左右擺動期（swing）熱圖資料。
  Future<SwingInfoHeatmapResponse> fetchSwingInfoHeatmap({
    required String sessionName,
    required SwingInfoHeatmapConfig config,
  }) {
    return _stageAnalysisApi.fetchSwingInfoHeatmap(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得 top-down 軌跡動畫資料包（前端自行渲染）。
  Future<TrajectoryPayloadResponse> fetchTrajectoryPayload({
    required String sessionName,
    required TrajectoryPayloadConfig config,
  }) {
    return _stageAnalysisApi.fetchTrajectoryPayload(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得步態週期相位分析資料。
  Future<GaitCyclePhasesResponse> fetchGaitCyclePhases({
    required String sessionName,
    required GaitCyclePhasesConfig config,
  }) {
    return _stageAnalysisApi.fetchGaitCyclePhases(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 取得每分鐘趨勢分析資料（速度與圈數）。
  Future<MinutelyTrendResponse> fetchMinutelyTrend({
    required String sessionName,
    required MinutelyTrendConfig config,
  }) {
    return _stageAnalysisApi.fetchMinutelyTrend(
      sessionName: sessionName,
      config: config,
    );
  }

  /// 觸發姿態擷取流程。
  Future<ExtractResult> triggerExtraction({
    String? bagId,
    String? bagPath,
    String? sessionName,
    String? userCode,
    ExtractConfig? config,
  }) {
    return _extractionApi.triggerExtraction(
      bagId: bagId,
      bagPath: bagPath,
      sessionName: sessionName,
      userCode: userCode,
      config: config,
    );
  }

  /// 分頁列出伺服器上的 bag 檔案清單。
  Future<BagFileListResponse> fetchServerBags({
    int page = 1,
    int pageSize = 50,
    bool recursive = true,
    String? query,
  }) {
    return _bagListApi.fetchServerBags(
      page: page,
      pageSize: pageSize,
      recursive: recursive,
      query: query,
    );
  }

  /// 分頁取得 Realsense session 列表。
  Future<RealsenseSessionList> fetchRealsenseSessions({
    int page = 1,
    int pageSize = 20,
    String? userCode,
    String? excludeUserCode,
    String? userName,
    String? excludeUserName,
    String match = 'exact',
    int limitUsers = 100,
  }) {
    return _sessionApi.fetchRealsenseSessions(
      page: page,
      pageSize: pageSize,
      userCode: userCode,
      excludeUserCode: excludeUserCode,
      userName: userName,
      excludeUserName: excludeUserName,
      match: match,
      limitUsers: limitUsers,
    );
  }

  /// 搜尋 session 名稱 AutoComplete 來源。
  Future<List<String>> searchSessionNames({
    required String keyword,
    int limit = 8,
  }) {
    return _sessionApi.searchSessionNames(keyword: keyword, limit: limit);
  }

  /// 刪除指定 Realsense session。
  Future<DeleteSessionResponse> deleteRealsenseSession({
    required String sessionName,
  }) async {
    final normalized = sessionName.trim();
    if (normalized.isEmpty) {
      throw ApiException(message: 'session_name 不可為空');
    }

    final response = await _sessionApi.deleteRealsenseSessionsBatch(
      request: DeleteSessionsBatchRequest(sessionNames: <String>[normalized]),
    );

    if (response.failed.contains(normalized)) {
      throw ApiException(message: '刪除失敗：$normalized');
    }

    final detail = response.details
        .where((e) => e.sessionName == normalized)
        .cast<DeleteSessionsBatchDetail?>()
        .firstWhere((e) => e != null, orElse: () => null);

    // 後端理論上會回傳 details；若沒有，至少回傳「推測成功」的結果避免 UI 崩潰。
    if (detail == null) {
      return DeleteSessionResponse(
        sessionName: normalized,
        deletedDb: response.deletedDb > 0,
        deletedNpy: response.deletedNpy > 0,
        deletedVideo: response.deletedVideo > 0,
        deletedBag: response.deletedBag > 0,
      );
    }

    return DeleteSessionResponse(
      sessionName: detail.sessionName,
      deletedDb: detail.deletedDb,
      deletedNpy: detail.deletedNpy,
      deletedVideo: detail.deletedVideo,
      deletedBag: detail.deletedBag,
    );
  }

  /// 批量刪除多個 Realsense sessions（1-100）。
  Future<DeleteSessionsBatchResponse> deleteRealsenseSessionsBatch({
    required DeleteSessionsBatchRequest request,
  }) {
    return _sessionApi.deleteRealsenseSessionsBatch(request: request);
  }

  // ===========================================================================
  // Users API
  // ===========================================================================

  /// 建立使用者（個案）。成功後回傳建立完成的使用者資料。
  Future<UserItem> createUser({required UserCreateRequest request}) {
    return _usersApi.createUser(request: request);
  }

  /// 取得使用者列表（分頁）。
  Future<UserListResponse> fetchUserList({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) {
    return _usersApi.fetchUserList(
      page: page,
      pageSize: pageSize,
      keyword: keyword,
    );
  }

  /// 搜尋使用者名稱建議。
  Future<List<String>> searchUserNames({
    required String keyword,
    int limit = 10,
  }) {
    return _usersApi.searchUserNames(keyword: keyword, limit: limit);
  }

  /// 依「name 前綴」搜尋使用者（可直接顯示清單）。
  Future<UserSearchSuggestionResponse> searchUserSuggestions({
    String? keyword,
    List<String>? cohorts,
    int page = 1,
    int pageSize = 20,
  }) {
    return _usersApi.searchUserSuggestions(
      keyword: keyword,
      cohorts: cohorts,
      page: page,
      pageSize: pageSize,
    );
  }

  /// 取得所有族群統計（結果可能快取）。
  Future<UserCohortsResponse> fetchUserCohorts({bool refresh = false}) {
    return _usersApi.fetchCohorts(refresh: refresh);
  }

  /// 取得使用者詳情（包含綁定的 sessions/bag 列表）。
  Future<UserDetailResponse> fetchUserDetail({required String userCode}) {
    return _usersApi.fetchUserDetail(userCode: userCode);
  }

  /// 更新使用者資料（PATCH）。
  ///
  /// 注意：此方法接受「差異化 patch」，避免不小心把未修改欄位清空。
  Future<UserItem> updateUser({
    required String userCode,
    required UserUpdateRequest request,
  }) {
    return _usersApi.updateUser(userCode: userCode, request: request);
  }

  /// 將指定 session(bag) 綁定到使用者。
  Future<UserSessionItem> linkUserToSession({
    required String userCode,
    required LinkUserSessionRequest request,
  }) {
    return _usersApi.linkSession(userCode: userCode, request: request);
  }

  /// 將指定 session(bag) 從使用者解除綁定。
  Future<UnlinkUserSessionResponse> unlinkUserFromSession({
    required String userCode,
    required UnlinkUserSessionRequest request,
  }) {
    return _usersApi.unlinkSession(userCode: userCode, request: request);
  }

  /// 批量刪除使用者（1-100）。
  Future<DeleteUsersBatchResponse> deleteUsersBatch({
    required DeleteUsersBatchRequest request,
  }) {
    return _usersApi.deleteUsersBatch(request: request);
  }

  /// 刪除指定使用者（內部仍走批量刪除端點）。
  Future<DeleteUserResponse> deleteUser({
    required String userCode,
    bool deleteSessions = false,
  }) async {
    final code = userCode.trim();
    if (code.isEmpty) {
      throw ApiException(message: 'user_code 不可為空');
    }

    final response = await _usersApi.deleteUsersBatch(
      request: DeleteUsersBatchRequest(
        userCodes: <String>[code],
        deleteSessions: deleteSessions,
      ),
    );

    if (response.failed.contains(code)) {
      throw ApiException(message: '刪除失敗：$code');
    }

    final detail = response.details
        .where((e) => e.userCode == code)
        .cast<DeleteUsersBatchDetail?>()
        .firstWhere((e) => e != null, orElse: () => null);

    if (detail == null) {
      return DeleteUserResponse(
        userCode: code,
        deletedUser: response.deletedUsers > 0,
        unlinkedSessions: response.totalUnlinkedSessions,
        deletedSessions: response.totalDeletedSessions,
      );
    }

    return DeleteUserResponse(
      userCode: detail.userCode,
      deletedUser: detail.deletedUser,
      unlinkedSessions: detail.unlinkedSessions,
      deletedSessions: detail.deletedSessions,
    );
  }

  // ===========================================================================
  // Cohort Benchmark API
  // ===========================================================================

  Future<CohortBenchmarkListResponse> fetchCohortBenchmarkList() {
    return _cohortBenchmarkApi.fetchCohortList();
  }

  Future<CohortUsersResponse> fetchCohortUsers({
    required CohortUsersRequest request,
  }) {
    return _cohortBenchmarkApi.fetchCohortUsers(request: request);
  }

  /// 取得指定 cohort 的基準值 detail（已計算）。
  ///
  /// 注意：後端若回 404 代表該 cohort 尚未有基準值（屬於可預期狀態），
  /// 此處回傳 null 讓 UI 顯示「需要逕行計算」，而不是顯示錯誤卡片。
  Future<CohortBenchmarkDetail?> fetchCohortBenchmarkDetail({
    required String cohortName,
  }) async {
    try {
      return await _cohortBenchmarkApi.fetchBenchmarkDetail(cohortName: cohortName);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CohortBenchmarkDetail> calculateCohortBenchmark({
    required String cohortName,
    bool forceRecalculate = false,
  }) {
    return _cohortBenchmarkApi.calculateBenchmark(
      cohortName: cohortName,
      forceRecalculate: forceRecalculate,
    );
  }

  Future<CohortBenchmarkCompareResponse> compareCohortBenchmark({
    required String sessionName,
    required String cohortName,
  }) {
    return _cohortBenchmarkApi.compare(
      sessionName: sessionName,
      cohortName: cohortName,
    );
  }

  Future<CohortBenchmarkDeleteBatchResponse> deleteCohortBenchmarks({
    required List<String> cohortNames,
  }) {
    return _cohortBenchmarkApi.deleteBenchmarks(cohortNames: cohortNames);
  }
}

/// 提供儀表板 repository 的 Riverpod Provider。
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    cohortBenchmarkApi: ref.watch(cohortBenchmarkApiServiceProvider),
    stageAnalysisApi: ref.watch(stageAnalysisApiServiceProvider),
    bagListApi: ref.watch(bagListApiServiceProvider),
    extractionApi: ref.watch(extractionApiServiceProvider),
    sessionApi: ref.watch(sessionApiServiceProvider),
    usersApi: ref.watch(usersApiServiceProvider),
  );
});
