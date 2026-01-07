import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';

/// Session 列表 / 搜尋相關 API
class SessionApiService {
  SessionApiService(this._dio);

  final Dio _dio;

  /// Realsense Pose Extractor 相關 API 的 base endpoint。
  static const _kRealsensePoseExtractorEndpoint = '/realsense-pose-extractor';

  /// 分頁取得 session 列表（`GET /realsense-pose-extractor/sessions`）。
  static const _sessionsEndpoint = '$_kRealsensePoseExtractorEndpoint/sessions';

  /// 批量刪除 sessions（`POST /realsense-pose-extractor/sessions/delete`）。
  static const _sessionsDeleteEndpoint =
      '$_kRealsensePoseExtractorEndpoint/sessions/delete';

  /// 依 session_name 前綴搜尋建議（`GET /realsense-pose-extractor/sessions/search`）。
  static const _sessionSearchEndpoint =
      '$_kRealsensePoseExtractorEndpoint/sessions/search';

  /// 取得單一 session 詳情（`GET /realsense-pose-extractor/sessions/{session_name}`）。
  static String _sessionDetailEndpoint(String sessionName) =>
      '$_sessionsEndpoint/${Uri.encodeComponent(sessionName)}';

  /// 檢查 session 影片可用性（`GET /realsense-pose-extractor/sessions/{session_name}/video-availability`）。
  static String _videoAvailabilityEndpoint(String sessionName) =>
      '${_sessionDetailEndpoint(sessionName)}/video-availability';

  Future<RealsenseSessionList> fetchRealsenseSessions({
    int page = 1,
    int pageSize = 20,
    String? userCode,
    String? excludeUserCode,
    String? userName,
    String? excludeUserName,
    String match = 'exact',
    int limitUsers = 100,
  }) async {
    final code = userCode?.trim();
    final excludeCode = excludeUserCode?.trim();
    final name = userName?.trim();
    final excludeName = excludeUserName?.trim();

    final query = <String, Object?>{
      'page': page,
      'page_size': pageSize,
      if (code != null && code.isNotEmpty) 'user_code': code,
      if (excludeCode != null && excludeCode.isNotEmpty)
        'exclude_user_code': excludeCode,
      if (name != null && name.isNotEmpty) 'user_name': name,
      if (excludeName != null && excludeName.isNotEmpty)
        'exclude_user_name': excludeName,
      'match': match,
      'limit_users': limitUsers,
    };

    Future<RealsenseSessionList> doGet(String endpoint) async {
      final response = await withApiRetry(
        () => _dio.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: query,
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return RealsenseSessionList.fromJson(body);
    }

    try {
      return await doGet(_sessionsEndpoint);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<String>> searchSessionNames({
    required String keyword,
    int limit = 10,
  }) async {
    final query = keyword.trim();
    if (query.isEmpty) {
      return const [];
    }

    Future<List<String>> doGet(String endpoint) async {
      final response = await withApiRetry(
        () => _dio.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: {'keyword': query, 'limit': limit},
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      final items = body['items'];
      if (items is List) {
        return items
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            // 固定長度列表，如後續呼叫 add 函數則會拋出異常
            .toList(growable: false);
      }
      return const [];
    }

    try {
      return await doGet(_sessionSearchEndpoint);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得單一 session 的詳細資訊。
  /// 
  /// 使用新的單一 session 查詢端點（2024-12-30 新增）。
  Future<RealsenseSessionItem?> fetchSessionDetail({
    required String sessionName,
  }) async {
    final name = sessionName.trim();
    if (name.isEmpty) {
      throw ApiException(message: 'session_name 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.get<Map<String, dynamic>>(
          _sessionDetailEndpoint(name),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return RealsenseSessionItem.fromJson(body);
    } on DioException catch (error) {
      // 404 表示找不到 session，返回 null 而非拋出異常
      if (error.response?.statusCode == 404) return null;
      throw mapDioError(error);
    }
  }

  /// 檢查 session 的影片可用性。
  /// 
  /// 輕量級端點，用於快速判斷 session 是否有影片可播放。
  /// 可區分「未生成影片」vs「影片檔案遺失」的情況。
  Future<VideoAvailability?> checkVideoAvailability({
    required String sessionName,
  }) async {
    final name = sessionName.trim();
    if (name.isEmpty) {
      throw ApiException(message: 'session_name 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.get<Map<String, dynamic>>(
          _videoAvailabilityEndpoint(name),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return VideoAvailability.fromJson(body);
    } on DioException catch (error) {
      // 404 表示找不到 session，返回 null 而非拋出異常
      if (error.response?.statusCode == 404) return null;
      throw mapDioError(error);
    }
  }

  /// 批量刪除多個 sessions（1-100）。
  Future<DeleteSessionsBatchResponse> deleteRealsenseSessionsBatch({
    required DeleteSessionsBatchRequest request,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _sessionsDeleteEndpoint,
        data: request.toJson(),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return DeleteSessionsBatchResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

final sessionApiServiceProvider = Provider<SessionApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return SessionApiService(dio);
});
