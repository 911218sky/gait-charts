import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/cookies/dio_cookie_support.dart';
import 'package:gait_charts/core/network/interceptors/auth_interceptor.dart';
import 'package:gait_charts/core/network/interceptors/request_compression_interceptor.dart';
import 'package:gait_charts/core/network/interceptors/signed_headers_interceptor.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_token_provider.dart';

/// 共用 Dio 實例，統一處理 baseUrl、逾時與 interceptor。
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final adminToken = ref.watch(adminTokenStateProvider);

  // 設定 Dio 基本選項
  final options = BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.requestTimeout,
    receiveTimeout: config.requestTimeout,
    sendTimeout: config.requestTimeout,
    headers: <String, Object?>{
      'Content-Type': 'application/json',
      if (adminToken != null && adminToken.isNotEmpty)
        'Authorization': 'Bearer $adminToken',
    },
  );

  final dio = Dio(options);

  // Cookie 支援：Web 由瀏覽器管理，非 Web 使用 CookieJar
  configureDioCookieSupport(dio);

  // 先壓縮再簽章，簽章須對實際送出的 bytes 計算
  dio.interceptors.add(RequestCompressionInterceptor(config: config));

  // 補上後端要求的簽章 headers
  dio.interceptors.add(SignedHeadersInterceptor(config: config));

  // 處理 401 Unauthorized：自動清除 token 並觸發登出
  dio.interceptors.add(AuthInterceptor(ref: ref));

  // Debug 模式下印出 403 錯誤，方便除錯權限問題
  if (kDebugMode) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final status = error.response?.statusCode;
          if (status == 403) {
            final req = error.requestOptions;
            debugPrint('[API][403] ${req.method} ${req.uri}');
            final body = error.response?.data;
            if (body != null) {
              debugPrint('[API][403] response: $body');
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  return dio;
});

/// API 重試次數預設值。
const int kDefaultApiRetryAttempts = 3;

/// 為 Dio 呼叫加上 retry 機制。
///
/// 僅對連線逾時、連線錯誤與 5xx 伺服器錯誤重試；4xx 等 client 錯誤直接拋出。
Future<Response<T>> withApiRetry<T>(
  Future<Response<T>> Function() request, {
  int maxAttempts = kDefaultApiRetryAttempts,
}) async {
  if (maxAttempts <= 0) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'must be >= 1');
  }

  var attempt = 0;
  while (true) {
    try {
      return await request();
    } on DioException catch (error) {
      attempt++;
      final isLastAttempt = attempt >= maxAttempts;
      if (isLastAttempt || !_shouldRetry(error)) {
        rethrow;
      }

      // 線性 backoff 避免打爆後端
      final delayMs = 250 * attempt;
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}

/// 判斷 Dio 錯誤是否適合重試。
bool _shouldRetry(DioException error) {
  final type = error.type;

  // 連線層級問題視為暫時性錯誤
  if (type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.connectionError) {
    return true;
  }

  // 5xx 伺服器錯誤也視為暫時性錯誤
  if (error.response?.statusCode != null &&
      error.response!.statusCode! >= 500 &&
      error.response!.statusCode! < 600) {
    return true;
  }

  return false;
}


