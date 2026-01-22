import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/admin/data/admin_auth_storage.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_token_provider.dart';

/// 處理 401 Unauthorized 的攔截器。
/// 收到 401 時自動清除 token 並重設狀態，讓 AdminAuthGate 導向登入頁。
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.ref});

  final Ref ref;

  /// 防止多個 401 同時觸發重複登出
  static bool _isLoggingOut = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    // 只處理 401 Unauthorized
    if (statusCode == 401) {
      _handleUnauthorized(err);
    }

    handler.next(err);
  }

  /// 處理 401：清除 token 並觸發登出
  Future<void> _handleUnauthorized(DioException err) async {
    // 防止重複觸發
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      if (kDebugMode) {
        final req = err.requestOptions;
        debugPrint('[Auth] 401 Unauthorized: ${req.method} ${req.uri}');
        debugPrint('[Auth] Token 已過期，正在自動登出...');
      }

      // 清除本機儲存的 token
      final storage = AdminAuthStorage();
      await storage.clear();

      // 清除 token 狀態，觸發 dioProvider 重建與 AdminAuthGate 登出偵測
      ref.read(adminTokenStateProvider.notifier).setToken(null);
    } finally {
      // 延遲重設 flag 避免短時間內重複觸發
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }
}
