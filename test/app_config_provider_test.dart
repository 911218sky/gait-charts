import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/core/storage/app_config_storage.dart';

class _FakeAppConfigStorage extends AppConfigStorage {
  _FakeAppConfigStorage({this.initialBaseUrl});

  final String? initialBaseUrl;
  String? _stored;
  bool _cleared = false;

  @override
  Future<String?> readBaseUrl() async => _cleared ? null : (_stored ?? initialBaseUrl);

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

void main() {
  test('appConfigAsyncProvider 會以本機 baseUrl 覆蓋 default', () async {
    final container = ProviderContainer(
      overrides: [
        appConfigStorageProvider.overrideWithValue(
          _FakeAppConfigStorage(initialBaseUrl: 'http://example.com/v1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final config = await container.read(appConfigAsyncProvider.future);
    expect(config.baseUrl, 'http://example.com/v1');
  });

  test('setBaseUrl 會更新同步 appConfigProvider 並寫入 storage', () async {
    final fakeStorage = _FakeAppConfigStorage();
    final container = ProviderContainer(
      overrides: [appConfigStorageProvider.overrideWithValue(fakeStorage)],
    );
    addTearDown(container.dispose);

    // 先確保 build 完成
    await container.read(appConfigAsyncProvider.future);

    await container.read(appConfigAsyncProvider.notifier).setBaseUrl(
      'http://localhost:8100/v1/',
    );

    expect(container.read(appConfigProvider).baseUrl, 'http://localhost:8100/v1');
    expect(await fakeStorage.readBaseUrl(), 'http://localhost:8100/v1');
  });

  test('resetToDefault 會清除 storage 並回到 default', () async {
    final fakeStorage = _FakeAppConfigStorage(initialBaseUrl: 'http://example.com/v1');
    final container = ProviderContainer(
      overrides: [appConfigStorageProvider.overrideWithValue(fakeStorage)],
    );
    addTearDown(container.dispose);

    await container.read(appConfigAsyncProvider.future);
    await container.read(appConfigAsyncProvider.notifier).resetToDefault();

    expect(container.read(appConfigProvider).baseUrl, defaultAppConfig.baseUrl);
    expect(await fakeStorage.readBaseUrl(), isNull);
  });
}


