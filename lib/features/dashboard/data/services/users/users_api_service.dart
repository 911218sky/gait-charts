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

  /// 取得/更新/刪除單一使用者（`GET|PATCH|DELETE /users/{user_code}`）。
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
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final k = keyword.trim();
    if (k.isEmpty) {
      return UserSearchSuggestionResponse(
        total: 0,
        page: 1,
        pageSize: pageSize,
        totalPages: 0,
        items: const [],
      );
    }
    try {
      final response = await withApiRetry(
        () => _dio.get<Object?>(
          _searchEndpoint,
          queryParameters: {
            'keyword': k,
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

  /// 刪除指定使用者。
  ///
  /// - deleteSessions=false（預設）：刪除使用者並解除該使用者名下 sessions 的綁定（保留 sessions）
  /// - deleteSessions=true：連同綁定的 sessions(DB 紀錄) 一併刪除
  Future<DeleteUserResponse> deleteUser({
    required String userCode,
    bool deleteSessions = false,
  }) async {
    final code = userCode.trim();
    if (code.isEmpty) {
      throw ApiException(message: 'user_code 不可為空');
    }
    try {
      final response = await _dio.delete<Object?>(
        _userByCodeEndpoint(code),
        queryParameters: {'delete_sessions': deleteSessions},
      );
      final body = response.data;
      if (body is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return DeleteUserResponse.fromJson(body.cast<String, Object?>());
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

final usersApiServiceProvider = Provider<UsersApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return UsersApiService(dio);
});
