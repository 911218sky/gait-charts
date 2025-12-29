import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/core/config/chart_config.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/storage/chart_config_storage.dart';

class _FakeChartConfigStorage extends ChartConfigStorage {
  _FakeChartConfigStorage({this.initial});

  final ChartConfig? initial;
  ChartConfig? _stored;
  bool _cleared = false;

  @override
  Future<ChartConfig?> readChartConfig() async {
    return _cleared ? null : (_stored ?? initial);
  }

  @override
  Future<void> writeChartConfig(ChartConfig config) async {
    _stored = config;
  }

  @override
  Future<void> clearChartConfig() async {
    _cleared = true;
    _stored = null;
  }
}

void main() {
  test('chartConfigProvider 會從本機還原設定', () async {
    final restored = defaultChartConfig.copyWith(perLapOverviewMaxPoints: 1500);
    final container = ProviderContainer(
      overrides: [
        chartConfigStorageProvider.overrideWithValue(
          _FakeChartConfigStorage(initial: restored),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 初始先是 default
    expect(container.read(chartConfigProvider), defaultChartConfig);

    // 等 microtask 的 restore 完成
    await Future<void>.delayed(Duration.zero);

    expect(container.read(chartConfigProvider).perLapOverviewMaxPoints, 1500);
  });

  test('更新設定會寫入 storage；reset 會清除並回到預設', () async {
    final fakeStorage = _FakeChartConfigStorage();
    final container = ProviderContainer(
      overrides: [
        chartConfigStorageProvider.overrideWithValue(fakeStorage),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chartConfigProvider.notifier);
    notifier.updateMultiFft(900);
    expect(container.read(chartConfigProvider).multiFftMaxPoints, 900);

    // storage 也應被寫入
    final stored = await fakeStorage.readChartConfig();
    expect(stored?.multiFftMaxPoints, 900);

    notifier.reset();
    expect(container.read(chartConfigProvider), defaultChartConfig);
    expect(await fakeStorage.readChartConfig(), isNull);
  });
}


