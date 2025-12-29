import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/services/analysis/stage_analysis_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/extraction/bag_list_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/extraction/extraction_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/sessions/session_api_service.dart';
import 'package:gait_charts/features/dashboard/data/services/users/users_api_service.dart';
import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 儀表板的資料存取層，封裝 API 呼叫與簡易轉換。
class DashboardRepository {
  DashboardRepository({
    required StageAnalysisApiService stageAnalysisApi,
    required BagListApiService bagListApi,
    required ExtractionApiService extractionApi,
    required SessionApiService sessionApi,
    required UsersApiService usersApi,
  }) : _stageAnalysisApi = stageAnalysisApi,
       _bagListApi = bagListApi,
       _extractionApi = extractionApi,
       _sessionApi = sessionApi,
       _usersApi = usersApi;

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

  /// 觸發姿態萃取流程。
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
  }) {
    return _sessionApi.deleteRealsenseSession(
      sessionName: sessionName,
    );
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
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) {
    return _usersApi.searchUserSuggestions(
      keyword: keyword,
      page: page,
      pageSize: pageSize,
    );
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

  /// 刪除指定使用者。
  Future<DeleteUserResponse> deleteUser({
    required String userCode,
    bool deleteSessions = false,
  }) {
    return _usersApi.deleteUser(
      userCode: userCode,
      deleteSessions: deleteSessions,
    );
  }
}

/// 提供儀表板 repository 的 Riverpod Provider。
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    stageAnalysisApi: ref.watch(stageAnalysisApiServiceProvider),
    bagListApi: ref.watch(bagListApiServiceProvider),
    extractionApi: ref.watch(extractionApiServiceProvider),
    sessionApi: ref.watch(sessionApiServiceProvider),
    usersApi: ref.watch(usersApiServiceProvider),
  );
});
