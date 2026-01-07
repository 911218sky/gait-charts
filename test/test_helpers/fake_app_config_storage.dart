import 'package:gait_charts/core/storage/app_config_storage.dart';

/// 讓 widget tests 不依賴 flutter_secure_storage（避免 MethodChannel 在測試環境卡住）。
class FakeAppConfigStorage extends AppConfigStorage {
  FakeAppConfigStorage({this.initialBaseUrl});

  final String? initialBaseUrl;
  String? _stored;
  bool _cleared = false;

  @override
  Future<String?> readBaseUrl() async {
    if (_cleared) return null;
    final value = _stored ?? initialBaseUrl;
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  Future<void> writeBaseUrl(String baseUrl) async {
    _stored = baseUrl;
  }

  @override
  Future<void> clearBaseUrl() async {
    _stored = null;
    _cleared = true;
  }
}


