import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/services/sessions/session_api_service.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';

/// 檢查 session 的影片可用性。
///
/// 使用輕量級 API 快速判斷影片狀態，可區分：
/// - 未生成影片（has_video=false）
/// - 影片檔案遺失（has_video=true, video_exists=false）
/// - 影片可播放（has_video=true, video_exists=true）
final videoAvailabilityProvider = FutureProvider.family
    .autoDispose<VideoAvailability?, String?>((ref, sessionName) async {
  if (sessionName == null || sessionName.trim().isEmpty) {
    return null;
  }
  
  final api = ref.watch(sessionApiServiceProvider);
  return api.checkVideoAvailability(sessionName: sessionName);
});
