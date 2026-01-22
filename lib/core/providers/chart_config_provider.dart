import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/chart_config.dart';
import 'package:gait_charts/core/storage/chart_config_storage.dart';

/// 圖表渲染設定管理，集中調整最大點數。
class ChartConfigNotifier extends Notifier<ChartConfig> {
  ChartConfigStorage get _storage => ref.read(chartConfigStorageProvider);

  @override
  ChartConfig build() {
    // 先用預設值避免 UI 等待 IO，再從本機背景還原
    unawaited(_restore());
    return defaultChartConfig;
  }

  Future<void> _restore() async {
    final stored = await _storage.readChartConfig();
    if (!ref.mounted || stored == null) {
      return;
    }
    state = stored;
  }

  void _setAndPersist(ChartConfig next) {
    if (next == state) {
      return;
    }
    state = next;
    unawaited(_storage.writeChartConfig(next));
  }

  void updateYHeightDiff(int value) {
    if (value == state.yHeightDiffMaxPoints) {
      return;
    }
    _setAndPersist(state.copyWith(yHeightDiffMaxPoints: value));
  }

  void updatePerLapSeries(int value) {
    if (value == state.perLapSeriesMaxPoints) {
      return;
    }
    _setAndPersist(state.copyWith(perLapSeriesMaxPoints: value));
  }

  void updatePerLapTheta(int value) {
    if (value == state.perLapThetaMaxPoints) {
      return;
    }
    _setAndPersist(state.copyWith(perLapThetaMaxPoints: value));
  }

  void updatePerLapOverview(int value) {
    if (value == state.perLapOverviewMaxPoints) {
      return;
    }
    _setAndPersist(state.copyWith(perLapOverviewMaxPoints: value));
  }

  void updateSpatialSpectrum(int value) {
    if (value == state.spatialSpectrumMaxPoints) {
      return;
    }
    _setAndPersist(state.copyWith(spatialSpectrumMaxPoints: value));
  }

  void updateMultiFft(int value) {
    if (value == state.multiFftMaxPoints) {
      return;
    }
    _setAndPersist(state.copyWith(multiFftMaxPoints: value));
  }

  /// 重設為預設值。
  void reset() {
    state = defaultChartConfig;
    unawaited(_storage.clearChartConfig());
  }
}

/// ChartConfig 本機儲存層。
final chartConfigStorageProvider = Provider<ChartConfigStorage>((ref) {
  return ChartConfigStorage();
});

/// ChartConfig provider，供 UI 調整或監聽。
final chartConfigProvider = NotifierProvider<ChartConfigNotifier, ChartConfig>(
  ChartConfigNotifier.new,
);
