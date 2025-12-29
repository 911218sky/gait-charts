import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/platform/platform_env.dart';

/// 目前執行環境的平台資訊（可在測試中 override）。
final platformEnvProvider = Provider<PlatformEnv>((ref) {
  return PlatformEnv.current();
});


