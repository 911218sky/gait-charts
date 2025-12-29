import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/cookies/dio_cookie_support.dart';
import 'package:gait_charts/core/network/interceptors/request_compression_interceptor.dart';
import 'package:gait_charts/core/network/interceptors/signed_headers_interceptor.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_token_provider.dart';

/// 建立共用的 Dio 實例，統一處理 baseUrl 與逾時等設定。
final dioProvider = Provider<Dio>((ref) {
  // 讀取應用程式設定與管理員 token
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

  // Cookie 支援：
  // - Web：由瀏覽器管理
  // - 非 Web：使用 CookieJar 保存/回送 Set-Cookie
  configureDioCookieSupport(dio);

  // 先壓縮、再簽章：簽章必須對「實際送上線的 bytes」計算，否則後端會驗不過。
  dio.interceptors.add(RequestCompressionInterceptor(config: config));

  // 送出請求前補上後端要求的簽章 headers（由 AppConfig 控制是否啟用）。
  dio.interceptors.add(SignedHeadersInterceptor(config: config));

  // 在 Debug 模式下加入最小化錯誤 Log：遇到 403 時印出 request/response，方便除錯權限或 token 問題。
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

/// 預設的 API 自動重試次數
const int kDefaultApiRetryAttempts = 3;

/// 對單一 Dio 呼叫包一層簡單 retry 機制。
///
/// - 僅對「連線逾時 / 連線錯誤」與 5xx 伺服器錯誤進行重試。
/// - 4xx 或明顯屬於 client 端錯誤則不會重試，直接拋出。
/// - 重試次數由 [maxAttempts] 控制，預設為 3 次。
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

      // 簡單的線性 backoff，避免過度打爆後端。
      final delayMs = 250 * attempt;
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}

/// 決定特定 Dio 錯誤是否適合自動重試。
bool _shouldRetry(DioException error) {
  final type = error.type;

  // 連線層級問題：連線失敗或逾時可視為暫時性錯誤。
  if (type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.connectionError) {
    return true;
  }

  // 如果服務器回傳 5xx 錯誤，也視為暫時性錯誤
  if (error.response?.statusCode != null &&
      error.response!.statusCode! >= 500 &&
      error.response!.statusCode! < 600) {
    return true;
  }

  return false;
}


