import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 使用者（個案）相關 API：建立 / 讀取 / 更新 / 綁定 session(bag)。
class UsersApiService {
  UsersApiService(this._dio);

  final Dio _dio;

  /// 使用者（個案）相關 API 的 base endpoint。
  static const _kUsersEndpoint = '/users';

  /// 依「name 前綴」搜尋使用者，回傳精簡 items（`GET /users/search`）。
  static const _searchEndpoint = '$_kUsersEndpoint/search';

  /// 取得/更新單一使用者（`GET|PATCH /users/{user_code}`）。
  ///
  /// 注意：包含 path param，無法用 const；統一透過此 helper 建立。
  static String _userByCodeEndpoint(String userCode) =>
      '$_kUsersEndpoint/${Uri.encodeComponent(userCode)}';

  /// 將 session(bag) 綁定到使用者（`POST /users/{user_code}/sessions/link`）。
  static String _linkSessionEndpoint(String userCode) =>
      '${_userByCodeEndpoint(userCode)}/sessions/link';

  /// 將 session(bag) 從使用者解除綁定（`POST /users/{user_code}/sessions/unlink`）。
  static String _unlinkSessionEndpoint(String userCode) =>
      '${_userByCodeEndpoint(userCode)}/sessions/unlink';

  /// 透過 BAG 檔案的 hash 值尋找使用者（`POST /users/find-by-bag`）。
  static const _findByBagEndpoint = '$_kUsersEndpoint/find-by-bag';

  /// 批量刪除使用者（`POST /users/delete`）。
  static const _deleteUsersEndpoint = '$_kUsersEndpoint/delete';

  /// 取得所有族群統計（`GET /users/cohorts`）。
  static const _cohortsEndpoint = '$_kUsersEndpoint/cohorts';

  Future<UserItem> createUser({required UserCreateRequest request}) async {
    try {
      final response = await _dio.post<Object?>(
        _kUsersEndpoint,
        data: request.toJson(),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return UserItem.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UserListResponse> fetchUserList({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    try {
      final q = keyword?.trim();
      final response = await withApiRetry(
        () => _dio.get<Object?>(
          _kUsersEndpoint,
          queryParameters: {
            'page': page,
            'page_size': pageSize,
            if (q != null && q.isNotEmpty) 'keyword': q,
          },
        ),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return UserListResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<String>> searchUserNames({
    required String keyword,
    int limit = 10,
  }) async {
    final response = await searchUserSuggestions(
      keyword: keyword,
      page: 1,
      pageSize: limit.clamp(1, 50),
    );
    return response.items.map((e) => e.name).toList(growable: false);
  }

  /// 依「name 前綴」搜尋使用者，回傳精簡 items（可直接用於 UI 清單）。
  Future<UserSearchSuggestionResponse> searchUserSuggestions({
    String? keyword,
    List<String>? cohorts,
    int page = 1,
    int pageSize = 20,
  }) async {
    final k = keyword?.trim() ?? '';
    final cohortList = (cohorts ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    try {
      final response = await withApiRetry(
        () => _dio.get<Object?>(
          _searchEndpoint,
          queryParameters: {
            if (k.isNotEmpty) 'keyword': k,
            if (cohortList.isNotEmpty) 'cohort': cohortList,
            // 後端新版支援分頁：page/page_size
            'page': page,
            'page_size': pageSize,
          },
        ),
      );
      final body = response.data;
      if (body is! Map) {
        return UserSearchSuggestionResponse(
          total: 0,
          page: 1,
          pageSize: pageSize,
          totalPages: 0,
          items: const [],
        );
      }
      return UserSearchSuggestionResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UserDetailResponse> fetchUserDetail({required String userCode}) async {
    final code = userCode.trim();
    if (code.isEmpty) {
      throw ApiException(message: 'user_code 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.get<Object?>(_userByCodeEndpoint(code)),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return UserDetailResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UserItem> updateUser({
    required String userCode,
    required UserUpdateRequest request,
  }) async {
    final code = userCode.trim();
    if (code.isEmpty) {
      throw ApiException(message: 'user_code 不可為空');
    }
    try {
      final response = await _dio.patch<Object?>(
        _userByCodeEndpoint(code),
        data: request.toJson(),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return UserItem.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UserSessionItem> linkSession({
    required String userCode,
    required LinkUserSessionRequest request,
  }) async {
    final code = userCode.trim();
    if (code.isEmpty) {
      throw ApiException(message: 'user_code 不可為空');
    }
    try {
      final response = await _dio.post<Object?>(
        _linkSessionEndpoint(code),
        data: request.toJson(),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return UserSessionItem.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UnlinkUserSessionResponse> unlinkSession({
    required String userCode,
    required UnlinkUserSessionRequest request,
  }) async {
    final code = userCode.trim();
    if (code.isEmpty) {
      throw ApiException(message: 'user_code 不可為空');
    }
    try {
      final response = await _dio.post<Object?>(
        _unlinkSessionEndpoint(code),
        data: request.toJson(),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return UnlinkUserSessionResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 批量刪除使用者（1-100）。
  Future<DeleteUsersBatchResponse> deleteUsersBatch({
    required DeleteUsersBatchRequest request,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        _deleteUsersEndpoint,
        data: request.toJson(),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return DeleteUsersBatchResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 透過 BAG 檔案名稱尋找使用者。
  ///
  /// 由於一個 bag 只能綁定一個使用者，最多只會找到一個使用者。
  Future<FindUserByBagResponse> findUserByBag({
    required FindUserByBagRequest request,
  }) async {
    final filename = request.bagFilename.trim();
    if (filename.isEmpty) {
      throw ApiException(message: 'bag_filename 不可為空');
    }
    try {
      final response = await withApiRetry(
        () => _dio.post<Object?>(
          _findByBagEndpoint,
          data: request.toJson(),
        ),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return FindUserByBagResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得所有族群統計（可用 refresh=true 強制刷新快取）。
  Future<UserCohortsResponse> fetchCohorts({bool refresh = false}) async {
    try {
      final response = await withApiRetry(
        () => _dio.get<Object?>(
          _cohortsEndpoint,
          queryParameters: {
            if (refresh) 'refresh': true,
          },
        ),
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return UserCohortsResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

final usersApiServiceProvider = Provider<UsersApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return UsersApiService(dio);
});
