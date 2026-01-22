import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/sessions/active_session_provider.dart';

/// 每分鐘趨勢資料 provider（速度與圈數）。
final minutelyTrendProvider =
    FutureProvider.autoDispose<MinutelyTrendResponse>((ref) async {
  final sessionName = ref.watch(activeSessionProvider).trim();
  if (sessionName.isEmpty) {
    return MinutelyTrendResponse.empty;
  }

  final config = ref.watch(minutelyTrendConfigProvider);
  final repository = ref.watch(dashboardRepositoryProvider);

  return repository.fetchMinutelyTrend(
    sessionName: sessionName,
    config: config,
  );
});

/// 每分鐘趨勢設定 provider。
final minutelyTrendConfigProvider =
    NotifierProvider<MinutelyTrendConfigNotifier, MinutelyTrendConfig>(
  MinutelyTrendConfigNotifier.new,
);

class MinutelyTrendConfigNotifier extends Notifier<MinutelyTrendConfig> {
  @override
  MinutelyTrendConfig build() => const MinutelyTrendConfig();

  void updateMaxMinutes(int? maxMinutes) {
    state = state.copyWith(maxMinutes: maxMinutes);
  }

  void reset() {
    state = const MinutelyTrendConfig();
  }
}
