import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 儀表板的主視圖分區。
enum DashboardSection {
  analysis,
  cohortBenchmark,
  perLapOffset,
  speedHeatmap,
  swingHeatmap,
  trajectoryPlayback,
  videoPlayback,
  frequency,
  yHeightDiff,
  apkDownloads,
  extraction,
  sessionManagement,
  users,
  admins,
}

/// 管理當前選擇的 Dashboard Section。
///
/// 讓子頁面可以透過 provider 切換到其他頁面（例如：從使用者頁面切換到影片播放頁面）。
final dashboardSectionProvider =
    NotifierProvider<DashboardSectionNotifier, DashboardSection>(
  DashboardSectionNotifier.new,
);

class DashboardSectionNotifier extends Notifier<DashboardSection> {
  @override
  DashboardSection build() => DashboardSection.analysis;

  /// 切換到指定的 section。
  void select(DashboardSection section) {
    state = section;
  }
}
