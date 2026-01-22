import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';
import 'stage_durations_state.dart';
import 'swing_info_heatmap_state.dart';

const String _kMinutelyCadenceRequestId = 'minutely_cadence_bars';
const String _kMinutelyCadenceForSwingRequestId = 'minutely_cadence_bars_swing';

/// 依照當前 Stage 設定組合出每分鐘步頻/步長的 API 設定。
final minutelyCadenceBarsConfigProvider =
    Provider<MinutelyCadenceStepLengthBarsConfig>((ref) {
      final stageConfig = ref.watch(stageDurationsConfigProvider);
      return MinutelyCadenceStepLengthBarsConfig(
        projection: stageConfig.projection,
        smoothWindow: stageConfig.smoothWindow,
        minVAbs: stageConfig.minVAbs,
        flatFrac: stageConfig.flatFrac,
      );
    });

/// 取得每分鐘步頻 / 步長柱狀圖資料。
final minutelyCadenceBarsProvider =
    FutureProvider<MinutelyCadenceStepLengthBarsResponse>((ref) async {
      final sessionName = ref.watch(activeSessionProvider).trim();
      if (sessionName.isEmpty) {
        ref.read(requestFailureStoreProvider.notifier).clearFailure(
              _kMinutelyCadenceRequestId,
            );
        return MinutelyCadenceStepLengthBarsResponse.empty;
      }
      final config = ref.watch(minutelyCadenceBarsConfigProvider);
      final repository = ref.watch(dashboardRepositoryProvider);
      final fingerprint = Object.hash(sessionName, config.toJson().toString());
      return fetchWithFailureGate(
        ref,
        requestId: _kMinutelyCadenceRequestId,
        fingerprint: fingerprint,
        fetch: () => repository.fetchMinutelyCadenceStepLengthBars(
          sessionName: sessionName,
          config: config,
        ),
      );
    });

/// 依照 Swing Heatmap 設定組合出每分鐘步頻/步長的 API 設定。
///
/// 設計目的：讓 Swing 熱圖頁可以用同一組參數，直接對照「swing 變化」與「步頻/步長變化」。
final minutelyCadenceBarsForSwingConfigProvider =
    Provider<MinutelyCadenceStepLengthBarsConfig>((ref) {
      // 只監聽「會影響 minutely API」的欄位：
      // - 避免 Swing 熱圖的視覺化色階 (vminPct/vmaxPct) 改動，導致這裡跟著重載。
      final projection = ref.watch(
        swingInfoHeatmapConfigProvider.select((c) => c.projection),
      );
      final smoothWindowS = ref.watch(
        swingInfoHeatmapConfigProvider.select((c) => c.smoothWindowS),
      );
      final minVAbs = ref.watch(
        swingInfoHeatmapConfigProvider.select((c) => c.minVAbs),
      );
      final flatFrac = ref.watch(
        swingInfoHeatmapConfigProvider.select((c) => c.flatFrac),
      );
      return MinutelyCadenceStepLengthBarsConfig(
        projection: projection,
        // minutely API 使用 int 秒數；Swing Heatmap 是 double 秒數，這裡做最小化轉換。
        smoothWindow: smoothWindowS.round().clamp(1, 30),
        minVAbs: minVAbs,
        flatFrac: flatFrac,
      );
    });

/// 取得 Swing 熱圖頁專用的每分鐘步頻 / 步長柱狀圖資料。
final minutelyCadenceBarsForSwingProvider =
    FutureProvider<MinutelyCadenceStepLengthBarsResponse>((ref) async {
      final sessionName = ref.watch(activeSessionProvider).trim();
      if (sessionName.isEmpty) {
        ref.read(requestFailureStoreProvider.notifier).clearFailure(
              _kMinutelyCadenceForSwingRequestId,
            );
        return MinutelyCadenceStepLengthBarsResponse.empty;
      }
      final config = ref.watch(minutelyCadenceBarsForSwingConfigProvider);
      final repository = ref.watch(dashboardRepositoryProvider);
      final fingerprint = Object.hash(sessionName, config.toJson().toString());
      return fetchWithFailureGate(
        ref,
        requestId: _kMinutelyCadenceForSwingRequestId,
        fingerprint: fingerprint,
        fetch: () => repository.fetchMinutelyCadenceStepLengthBars(
          sessionName: sessionName,
          config: config,
        ),
      );
    });
