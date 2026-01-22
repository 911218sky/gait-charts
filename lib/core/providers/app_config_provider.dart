import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/config/base_url.dart';
import 'package:gait_charts/core/storage/app_config_storage.dart';

/// AppConfig 本機儲存層。
final appConfigStorageProvider = Provider<AppConfigStorage>((ref) {
  return AppConfigStorage();
});

/// AppConfig 狀態管理，包含從本機載入與寫入。
class AppConfigNotifier extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() async {
    final storage = ref.watch(appConfigStorageProvider);

    try {
      // widget_test 環境中 storage plugin 可能卡住，加 timeout 避免 App 停在載入畫面
      final storedBaseUrl = await storage
          .readBaseUrl()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (storedBaseUrl == null) {
        return defaultAppConfig;
      }
      final normalized = normalizeBaseUrl(storedBaseUrl);
      return defaultAppConfig.copyWith(baseUrl: normalized);
    } catch (_) {
      // 本機設定損壞時回退到預設，避免 App 無法啟動
      return defaultAppConfig;
    }
  }

  Future<void> setBaseUrl(String input) async {
    final storage = ref.read(appConfigStorageProvider);
    final next = normalizeBaseUrl(input);
    await storage.writeBaseUrl(next);
    final current = state.value ?? defaultAppConfig;
    state = AsyncData(current.copyWith(baseUrl: next));
  }

  Future<void> resetToDefault() async {
    final storage = ref.read(appConfigStorageProvider);
    await storage.clearBaseUrl();
    state = const AsyncData(defaultAppConfig);
  }
}

/// 內部 async provider：載入/保存 AppConfig。
final appConfigAsyncProvider = AsyncNotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);

/// 同步的 AppConfig（載入中或錯誤時回退 default），供 dioProvider 等同步 provider 使用。
final appConfigProvider = Provider<AppConfig>((ref) {
  final asyncConfig = ref.watch(appConfigAsyncProvider);
  return asyncConfig.value ?? defaultAppConfig;
});
