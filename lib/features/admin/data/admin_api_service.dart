import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/domain/models/admin_requests.dart';

/// 管理員 API service（data layer / network）。
///
/// 職責：
/// - 只負責打 API、把 response 轉成 domain model
/// - 統一把 Dio 例外透過 `mapDioError` 轉成可讀的 `ApiException`
/// - 需要重試的請求使用 `withApiRetry(...)`
class AdminApiService {
  AdminApiService(this._dio);

  /// 專案共用的 Dio 實例（由 `dioProvider` 注入），避免在 UI/new Dio。
  final Dio _dio;

  /// 管理員相關 API 的 base endpoint。
  static const _kAdminsEndpoint = '/admins';

  // Endpoints（集中管理，避免散落在各方法內）
  /// 登入（`POST /admins/login`）。
  static const _loginEndpoint = '$_kAdminsEndpoint/login';

  /// 註冊（`POST /admins/register`）。
  static const _registerEndpoint = '$_kAdminsEndpoint/register';

  /// 取得/更新目前管理員資訊（`GET|PATCH /admins/me`）。
  static const _meEndpoint = '$_kAdminsEndpoint/me';

  /// 登出（`POST /admins/logout`）。
  static const _logoutEndpoint = '$_kAdminsEndpoint/logout';

  /// 變更密碼（`POST /admins/password/change`）。
  static const _changePasswordEndpoint = '$_kAdminsEndpoint/password/change';

  /// 建立邀請碼（`POST /admins/invitations`）。
  static const _invitationsEndpoint = '$_kAdminsEndpoint/invitations';

  /// 帶上 Bearer token 的 request options。
  Options _authOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// 登入（`POST /admins/login`）。
  ///
  /// 成功回傳 `AuthSession`（含 token / expiresAt / admin）。
  /// 失敗時會丟出已映射過的 `ApiException`。
  Future<AuthSession> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Object?>(
        _loginEndpoint,
        data: request.toJson(),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return _parseAuthSession(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 註冊（`POST /admins/register`）。
  ///
  /// 成功回傳 `AuthSession`；失敗時會丟出 `ApiException`。
  Future<AuthSession> register(RegisterRequest request) async {
    try {
      final response = await _dio.post<Object?>(
        _registerEndpoint,
        data: request.toJson(),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return _parseAuthSession(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得目前管理員資訊（`GET /admins/me`）。
  ///
  /// 需要帶 token；成功回傳 `AdminPublic`。
  Future<AdminPublic> fetchMe(String token) async {
    try {
      final response = await _dio.get<Object?>(
        _meEndpoint,
        options: _authOptions(token),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return AdminPublic.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 更新目前管理員資訊（`PATCH /admins/me`）。
  ///
  /// 需要帶 token；成功回傳更新後的 `AdminPublic`。
  Future<AdminPublic> updateMe({
    required String token,
    required AdminUpdateMeRequest request,
  }) async {
    try {
      final response = await _dio.patch<Object?>(
        _meEndpoint,
        data: request.toJson(),
        options: _authOptions(token),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return AdminPublic.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 登出（`POST /admins/logout`）。
  ///
  /// - 需要帶 token
  /// - 若伺服器沒有回傳預期 JSON，這裡會回傳「視為已登出」的預設結果，
  ///   讓上層流程不中斷（本機仍可自行清 token）。
  Future<LogoutResult> logout(String token) async {
    try {
      final response = await _dio.post<Object?>(
        _logoutEndpoint,
        options: _authOptions(token),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        return const LogoutResult(loggedOut: true, sessionRevoked: false);
      }
      return LogoutResult.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 變更密碼（`POST /admins/password/change`）。
  ///
  /// 需要帶 token；成功回傳新的 `AuthSession`（伺服器可能會旋轉 token）。
  Future<AuthSession> changePassword({
    required String token,
    required ChangePasswordRequest request,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        _changePasswordEndpoint,
        data: request.toJson(),
        options: _authOptions(token),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return _parseAuthSession(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 建立邀請碼（`POST /admins/invitations`）。
  Future<InvitationCode> createInvitation({
    required String token,
    required InvitationCreateRequest request,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        _invitationsEndpoint,
        data: request.toJson(),
        options: _authOptions(token),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return InvitationCode.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得管理員列表（`GET /admins`，分頁）。
  ///
  /// 此請求可能受網路抖動影響，使用 `withApiRetry` 做輕量重試。
  Future<AdminListResponse> listAdmins({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.get<Object?>(
          _kAdminsEndpoint,
          queryParameters: {
            'page': page,
            'page_size': pageSize,
          },
          options: _authOptions(token),
        ),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return AdminListResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 刪除管理員（`DELETE /admins/{adminCode}`）。
  Future<DeleteAdminResult> deleteAdmin({
    required String token,
    required String adminCode,
  }) async {
    try {
      final response = await _dio.delete<Object?>(
        '$_kAdminsEndpoint/$adminCode',
        options: _authOptions(token),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return DeleteAdminResult.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 解析登入/註冊/改密碼回傳的 session payload。
  ///
  /// 這裡做了「容錯」：
  /// - token/expires_at/admin 欄位缺漏時給預設值，避免因後端資料格式小變動而直接崩潰
  /// - 但上層仍應視情況判斷 token 是否為空字串、expiresAt 是否合理
  AuthSession _parseAuthSession(Map<String, Object?> json) {
    final token = (json['token'] as String?)?.trim() ?? '';
    final expiresAt = (json['expires_at'] as String?)?.trim();
    final adminRaw = json['admin'];
    return AuthSession(
      token: token,
      expiresAt: expiresAt != null
          ? DateTime.tryParse(expiresAt) ??
              // 如果解析失敗，則使用 1970-01-01 00:00:00
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      admin: adminRaw is Map<String, Object?>
          ? AdminPublic.fromJson(adminRaw)
          : AdminPublic(
              adminCode: '',
              username: '',
              invitedByCode: null,
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
    );
  }
}

/// 管理員 API service provider（從 `dioProvider` 注入共用 Dio）。
final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminApiService(dio);
});

