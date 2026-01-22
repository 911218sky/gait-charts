import 'package:dio/dio.dart';

/// API 異常，封裝錯誤訊息與 HTTP 狀態碼。
class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.original});

  /// 錯誤訊息
  final String message;

  /// HTTP 狀態碼
  final int? statusCode;

  /// 原始錯誤物件
  final Object? original;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 從伺服器回傳的 body 取出可讀訊息。
String? _extractServerMessage(Response<dynamic>? response) {
  // 將 dynamic 轉換為 String
  String? asString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  final data = response?.data;
  if (data is Map<String, dynamic>) {
    final direct = asString(data['detail']) ?? asString(data['message']);
    if (direct != null) {
      return direct;
    }
  }
  return null;
}

/// 將 DioException 轉換為 UI 友善的 ApiException。
ApiException mapDioError(DioException error) {
  // 處理連線逾時
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return ApiException(
      message: '連線逾時，請稍後再試。',
      statusCode: error.response?.statusCode,
      original: error,
    );
  }

  // 處理伺服器回傳錯誤
  if (error.type == DioExceptionType.badResponse) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _extractServerMessage(error.response);
    return ApiException(
      message: serverMessage ??
          '伺服器回傳錯誤（${statusCode ?? '未知'}），請求失敗。',
      statusCode: statusCode,
      original: error,
    );
  }

  // 處理連線錯誤
  if (error.type == DioExceptionType.connectionError) {
    return ApiException(
      message: '無法連線至伺服器，請確認網路或 API 狀態。',
      statusCode: error.response?.statusCode,
      original: error,
    );
  }

  // 其他未知錯誤
  return ApiException(
    message: '發生未知錯誤，請稍後再試。',
    statusCode: error.response?.statusCode,
    original: error,
  );
}


