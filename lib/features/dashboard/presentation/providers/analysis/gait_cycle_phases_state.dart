import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/analysis/swing_info_heatmap_state.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/sessions/active_session_provider.dart';

/// 步態週期相位資料 Provider。
///
/// 依賴 [activeSessionProvider] 與 [swingInfoHeatmapConfigProvider] 的 projection，
/// 當 session 或 projection 改變時自動重新載入。
final gaitCyclePhasesProvider =
    FutureProvider.autoDispose<GaitCyclePhasesResponse>((ref) async {
  final session = ref.watch(activeSessionProvider);
  if (session.isEmpty) {
    return GaitCyclePhasesResponse.empty;
  }

  // 使用與 swing heatmap 相同的 projection 設定
  final projection = ref.watch(
    swingInfoHeatmapConfigProvider.select((c) => c.projection),
  );

  final config = GaitCyclePhasesConfig(projection: projection);
  final repo = ref.watch(dashboardRepositoryProvider);

  // 計算 fingerprint 用於 failure gate
  final fingerprint = Object.hash(session, projection);

  return fetchWithFailureGate(
    ref,
    requestId: 'gait_cycle_phases',
    fingerprint: fingerprint,
    fetch: () => repo.fetchGaitCyclePhases(
      sessionName: session,
      config: config,
    ),
  );
});
