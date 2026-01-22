import 'package:flutter/material.dart';

/// App 的版面 breakpoints（集中維護，避免散落 magic number）。
///
/// 命名原則：用「用途」命名，而不是用 device 名稱，避免需求變更時語意混亂。
class AppLayoutBreakpoints {
  const AppLayoutBreakpoints._();

  /// 小螢幕（手機）判定。
  static const double mobile = 600;

  /// Header / toolbar 類型在窄寬度下的切換點（改成直向/Wrap）。
  static const double compactHeader = 700;

  /// Tablet / 中等寬度判定（用於對話框/選擇器是否走雙欄）。
  static const double tablet = 900;

  /// Dashboard 進入 sidebar/rail 模式的切換點。
  static const double dashboardSidebar = 1100;

  /// Trajectory 播放頁是否改成「設定走 bottom sheet」的切換點。
  static const double trajectoryCompact = 980;

  /// 大螢幕雙欄資訊卡（users/detail 等）切換點。
  static const double desktopWide = 1200;

  /// Analysis 詳細區（chart + details）雙欄切換點。
  static const double analysisWide = 1200;
}

/// 提供 BuildContext 的常用擴充方法，簡化 Theme 與 UI 存取。
///
/// 這些方法是與具體 App Theme 實作解耦的通用工具。
extension ThemeContextExtension on BuildContext {
  /// 快速取得目前主題的 ThemeData。
  ThemeData get theme => Theme.of(this);

  /// 判斷目前是否為深色模式。
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// 快速取得目前主題的 ColorScheme。
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 快速取得目前主題的 TextTheme。
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 快速取得目前主題的背景顏色。
  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;

  /// 快速取得目前主題的卡片顏色。
  Color get cardColor => Theme.of(this).cardColor;

  /// 快速取得目前主題的分隔線顏色。
  Color get dividerColor => Theme.of(this).dividerColor;

  /// 快速取得目前主題的懸浮顏色。
  Color get hoverColor => Theme.of(this).hoverColor;

  /// 快速取得目前主題的禁用顏色。
  Color get disabledColor => Theme.of(this).disabledColor;

  /// 快速取得目前主題的 DialogTheme。
  DialogThemeData get dialogTheme => Theme.of(this).dialogTheme;

  /// 快速取得目前主題的 IconTheme。
  IconThemeData get iconTheme => Theme.of(this).iconTheme;

  /// 快速取得擴充屬性 (ThemeExtension)。
  T? extension<T>() => Theme.of(this).extension<T>();
}

/// 提供 BuildContext 的 layout 相關擴充（集中使用 MediaQuery）。
extension LayoutContextExtension on BuildContext {
  /// 螢幕寬度（等同於 `MediaQuery.sizeOf(context).width`）。
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// 螢幕高度（等同於 `MediaQuery.sizeOf(context).height`）。
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// 是否為手機寬度。
  bool get isMobile => screenWidth < AppLayoutBreakpoints.mobile;

  /// Header / toolbar 是否應採用 compact 版面。
  bool get isCompactHeader => screenWidth < AppLayoutBreakpoints.compactHeader;

  /// 是否達到 tablet 寬度。
  bool get isTabletWide => screenWidth >= AppLayoutBreakpoints.tablet;

  /// Dashboard 是否使用 sidebar/rail。
  bool get useDashboardSidebar => screenWidth >= AppLayoutBreakpoints.dashboardSidebar;

  /// Trajectory 是否使用 compact 版面（設定改走 bottom sheet）。
  bool get isTrajectoryCompact =>
      screenWidth < AppLayoutBreakpoints.trajectoryCompact;

  /// 是否為大螢幕（>= desktopWide）。
  bool get isDesktopWide => screenWidth >= AppLayoutBreakpoints.desktopWide;

  /// Analysis 詳細區是否使用雙欄（> analysisWide）。
  bool get isAnalysisWide => screenWidth > AppLayoutBreakpoints.analysisWide;
}

/// 提供 BuildContext 的 Navigator 相關擴充。
extension NavigatorContextExtension on BuildContext {
  /// 快速取得 NavigatorState（等同於 `Navigator.of(context)`）。
  NavigatorState get navigator => Navigator.of(this);
}