import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gait_charts/core/storage/secure_storage_config.dart';

/// 軌跡播放器 UI 偏好設定的本機持久化。
/// 目前存 showFullTrail：true 顯示完整軌跡，false 顯示當圈。
class TrajectoryOverlayStorage {
  TrajectoryOverlayStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageConfig.instance;

  final FlutterSecureStorage _storage;

  static const _kShowFullTrailKey = 'trajectory.overlay.show_full_trail';

  Future<bool?> readShowFullTrail() async {
    final raw = await _storage.read(key: _kShowFullTrailKey);
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
    return null;
  }

  Future<void> writeShowFullTrail(bool value) async {
    await _storage.write(key: _kShowFullTrailKey, value: value ? 'true' : 'false');
  }

  Future<void> clearShowFullTrail() async {
    await _storage.delete(key: _kShowFullTrailKey);
  }
}


