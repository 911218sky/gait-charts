import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gait_charts/core/config/chart_config.dart';
import 'package:gait_charts/core/storage/secure_storage_config.dart';

/// ChartConfig 本機持久化。
class ChartConfigStorage {
  ChartConfigStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageConfig.instance;

  final FlutterSecureStorage _storage;

  static const String _kChartConfigKey = 'app.chart_config';

  Future<ChartConfig?> readChartConfig() async {
    final raw = await _storage.read(key: _kChartConfigKey);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ChartConfig.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeChartConfig(ChartConfig config) async {
    await _storage.write(
      key: _kChartConfigKey,
      value: jsonEncode(config.toJson()),
    );
  }

  Future<void> clearChartConfig() async {
    await _storage.delete(key: _kChartConfigKey);
  }
}
