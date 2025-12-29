import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/config/base_url.dart';
import 'package:gait_charts/core/storage/app_config_storage.dart';

/// AppConfig 的本機儲存層 Provider。
final appConfigStorageProvider = Provider<AppConfigStorage>((ref) {
  return AppConfigStorage();
});

/// 管理 AppConfig 的可變狀態（包含從本機載入與寫入）。
class AppConfigNotifier extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() async {
    final storage = ref.watch(appConfigStorageProvider);

    try {
      final storedBaseUrl = await storage.readBaseUrl();
      if (storedBaseUrl == null) {
        return defaultAppConfig;
      }
      final normalized = normalizeBaseUrl(storedBaseUrl);
      return defaultAppConfig.copyWith(baseUrl: normalized);
    } catch (_) {
      // 本機設定如果壞掉（例如格式錯誤），直接回退到預設，避免整個 App 無法啟動。
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

/// 內部 async provider：負責載入/保存 AppConfig。
final appConfigAsyncProvider = AsyncNotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);

/// 對外提供同步的 AppConfig（載入中或錯誤時回退 default）。
///
/// 這樣像 `dioProvider` 這類同步 provider 不需要大改。
final appConfigProvider = Provider<AppConfig>((ref) {
  final asyncConfig = ref.watch(appConfigAsyncProvider);
  return asyncConfig.value ?? defaultAppConfig;
});
