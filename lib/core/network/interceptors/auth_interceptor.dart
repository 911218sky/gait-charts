import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/admin/data/admin_auth_storage.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_token_provider.dart';

/// 處理 401 Unauthorized 錯誤的攔截器。
///
/// 當 API 回傳 401 時，自動清除本機 token 並重設 token 狀態，
/// 讓 AdminAuthGate 偵測到登出狀態並導向登入頁面。
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.ref});

  final Ref ref;

  /// 用於防止多個 401 同時觸發重複登出
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

  /// 處理 401 錯誤：清除 token 並觸發登出
  Future<void> _handleUnauthorized(DioException err) async {
    // 防止多個 401 同時觸發重複登出
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

      // 清除 token 狀態，這會觸發 dioProvider 重建
      // 並讓 AdminAuthGate 偵測到登出狀態
      ref.read(adminTokenStateProvider.notifier).setToken(null);
    } finally {
      // 延遲重設 flag，避免短時間內重複觸發
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }
}
