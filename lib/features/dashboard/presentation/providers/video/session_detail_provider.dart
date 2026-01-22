import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/services/sessions/session_api_service.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';

/// 取得單一 session 的詳細資訊（包含 bag_filename）。
///
/// 優先使用單一 session 詳情 API（2024-12-30 新增），失敗時 fallback 到列表 API。
final sessionDetailProvider = FutureProvider.family
    .autoDispose<RealsenseSessionItem?, String?>((ref, sessionName) async {
  if (sessionName == null || sessionName.trim().isEmpty) {
    return null;
  }
  
  final api = ref.watch(sessionApiServiceProvider);
  
  try {
    // 先嘗試單一 session 詳情 API
    return await api.fetchSessionDetail(sessionName: sessionName);
  } catch (_) {
    // fallback: 使用列表 API 取得 session 資訊
    try {
      final result = await api.fetchRealsenseSessions(
        page: 1,
        pageSize: 500,
      );
      
      for (final session in result.items) {
        if (session.sessionName == sessionName) {
          return session;
        }
      }
      
      return null;
    } catch (_) {
      return null;
    }
  }
});
