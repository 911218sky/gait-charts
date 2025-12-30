import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/app/widgets/app_connection_settings_panel.dart';
import 'package:gait_charts/app/widgets/window_title_bar.dart';
import 'package:gait_charts/core/platform/platform_env.dart';
import 'package:gait_charts/core/platform/window_manager_initializer.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/views/admin_management_view.dart';
import 'package:gait_charts/features/apk/presentation/views/apk_downloads_view.dart';
import 'package:gait_charts/features/dashboard/domain/feature_availability.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/views/dashboard_analysis_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/dashboard_extraction_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/dashboard_users_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/frequency_analysis_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/speed_heatmap_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/swing_info_heatmap_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/trajectory_playback_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/video_playback_view.dart';
import 'package:gait_charts/features/dashboard/presentation/views/y_height_diff_view.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/per_lap_offset/per_lap_offset_view.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/settings/chart_config_panel.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/navigation/sidebar_navigation.dart';

/// 儀表板主畫面，整合分析、偏移與資料提取等子頁。
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

/// 定義儀表板的主視圖分區。
enum _DashboardSection {
  analysis,
  perLapOffset,
  speedHeatmap,
  swingHeatmap,
  trajectoryPlayback,
  videoPlayback,
  frequency,
  yHeightDiff,
  apkDownloads,
  extraction,
  users,
  admins,
}

/// 管理儀表板導覽邏輯與 session 控制。
class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // 設定預設選擇的區塊
  _DashboardSection _selectedSection = _DashboardSection.analysis;
  // 設定 session 控制器
  late final TextEditingController _sessionController;
  // 設定 stage 訂閱
  late final ProviderSubscription<AsyncValue<StageDurationsResponse>>
  _stageSubscription;

  @override
  void initState() {
    super.initState();
    _sessionController = TextEditingController(
      text: ref.read(activeSessionProvider),
    );

    // 監聽分析資料的變化，當資料更新且目前沒有選擇圈數時，自動選擇第一圈
    _stageSubscription = ref.listenManual<AsyncValue<StageDurationsResponse>>(
      stageDurationsProvider,
      // next 會有 AsyncValue<StageDurationsResponse> next
      (previous, next) {
        // 當資料更新時，更新選擇的圈數
        next.whenData((response) {
          final laps = response.laps;
          final notifier = ref.read(selectedLapIndexProvider.notifier);
          if (laps.isEmpty) {
            notifier.select(null);
            return;
          }
          final current = ref.read(selectedLapIndexProvider);
          final hasCurrent =
              current != null && laps.any((lap) => lap.lapIndex == current);
          if (!hasCurrent) {
            notifier.select(laps.first.lapIndex);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _stageSubscription.close();
    _sessionController.dispose();
    super.dispose();
  }

  void _showToast(
    String message, {
    DashboardToastVariant variant = DashboardToastVariant.info,
  }) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  void _onSelectSection(
    _DashboardSection next, {
    DashboardFeature? featureGate,
  }) {
    if (next == _selectedSection) {
      return;
    }

    if (featureGate != null) {
      final env = PlatformEnv.current();
      final message = const DashboardFeatureAvailability().blockedMessage(
        feature: featureGate,
        env: env,
      );
      if (message != null) {
        _showToast(message, variant: DashboardToastVariant.warning);
        return;
      }
    }

    setState(() => _selectedSection = next);
  }

  // 載入指定的 Session 資料
  Future<void> _loadSession() async {
    final session = _sessionController.text.trim();
    if (session.isEmpty) {
      _showToast('請先輸入 session 名稱', variant: DashboardToastVariant.warning);
      return;
    }
    ref.read(activeSessionProvider.notifier).setSession(session);
    // 將 stageDurationsProvider 的資料失效，重新獲取資料，這樣會觸發 stageDurationsProvider 的重新執行
    ref.invalidate(stageDurationsProvider);
  }

  void _showChartConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: const ChartConfigPanel(),
        ),
      ),
    );
  }

  void _showConnectionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: const AppConnectionSettingsPanel(),
        ),
      ),
    );
  }

  Future<void> _showMoreSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.colorScheme;
        final themeMode = ref.read(themeModeProvider);

        final itemsByGroup = <String, List<_DashboardNavItem>>{};
        for (final item in _navItems) {
          (itemsByGroup[item.sidebarGroup] ??= <_DashboardNavItem>[]).add(item);
        }

        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    '更多',
                    style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '頁面',
                    style: context.textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in itemsByGroup.entries) ...[
                    const SizedBox(height: 12),
                    Text(
                      entry.key,
                      style: context.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in entry.value)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(item.icon),
                        title: Text(item.sidebarLabel),
                        trailing: item.section == _selectedSection
                            ? Icon(Icons.check, color: colors.primary)
                            : null,
                        onTap: () {
                          context.navigator.pop();
                          _onSelectSection(
                            item.section,
                            featureGate: item.featureGate,
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: 8),
                  Text(
                    '設定',
                    style: context.textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_ethernet),
                    title: const Text('連線設定'),
                    onTap: () {
                      context.navigator.pop();
                      _showConnectionSettingsDialog();
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.tune),
                    title: const Text('Chart Settings'),
                    onTap: () {
                      context.navigator.pop();
                      _showChartConfigDialog();
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      themeMode == ThemeMode.light
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    title: const Text('切換主題'),
                    onTap: () {
                      context.navigator.pop();
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: const Text('登出管理員'),
                    onTap: () async {
                      context.navigator.pop();
                      await ref.read(adminAuthProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 寬螢幕時使用側邊欄
    final useRail = context.useDashboardSidebar;
    // 只要不是側邊欄模式，就使用「主 tab + 更多」的底部導覽（避免 9 個 tab 擠爆）。
    final useCompactBottomNav = !useRail;

    const compactSections = <_DashboardSection>[
      _DashboardSection.analysis,
      _DashboardSection.speedHeatmap,
      _DashboardSection.swingHeatmap,
      _DashboardSection.trajectoryPlayback,
    ];
    // 選擇的索引
    final selectedIndex = useCompactBottomNav
        ? () {
            final idx = compactSections.indexOf(_selectedSection);
            return idx >= 0 ? idx : compactSections.length;
          }()
        : _navItems.indexWhere((it) => it.section == _selectedSection);

    final Widget content;
    switch (_selectedSection) {
      case _DashboardSection.analysis:
        content = DashboardAnalysisView(
          key: const ValueKey('analysis-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.perLapOffset:
        content = PerLapOffsetView(
          key: const ValueKey('per-lap-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.speedHeatmap:
        content = SpeedHeatmapView(
          key: const ValueKey('speed-heatmap-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.swingHeatmap:
        content = SwingInfoHeatmapView(
          key: const ValueKey('swing-heatmap-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.trajectoryPlayback:
        content = TrajectoryPlaybackView(
          key: const ValueKey('trajectory-playback-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.videoPlayback:
        content = VideoPlaybackView(
          key: const ValueKey('video-playback-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.frequency:
        content = FrequencyAnalysisView(
          key: const ValueKey('frequency-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.yHeightDiff:
        content = YHeightDiffView(
          key: const ValueKey('y-height-view'),
          sessionController: _sessionController,
          onLoadSession: _loadSession,
        );
        break;
      case _DashboardSection.apkDownloads:
        content = const ApkDownloadsView(key: ValueKey('apk-downloads-view'));
        break;
      case _DashboardSection.extraction:
        content = DashboardExtractionView(
          key: const ValueKey('extraction-view'),
          sessionValue: _sessionController.text.trim(),
          onCompleted: (result) {
            _showToast(
              '成功產生 session：${result.sessionName}',
              variant: DashboardToastVariant.success,
            );
            _sessionController.text = result.sessionName;
            ref
                .read(activeSessionProvider.notifier)
                .setSession(result.sessionName);
            ref.invalidate(stageDurationsProvider);
          },
        );
        break;
      case _DashboardSection.users:
        content = const DashboardUsersView(key: ValueKey('users-view'));
        break;
      case _DashboardSection.admins:
        content = const AdminManagementView(key: ValueKey('admins-view'));
        break;
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      extendBody: true,
      body: Column(
        children: [
          if (kShowCustomTitleBar) const AppWindowTitleBar(),
          Expanded(
            child: SafeArea(
              // 有自訂 title bar 時，不需要再吃 top safe area，避免多一段空白。
              top: !kShowCustomTitleBar,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (useRail)
                    SidebarNavigation(
                      destinations: _sidebarDestinations,
                      selectedIndex: selectedIndex,
                      onChanged: (index) {
                        final item = _navItems[index];
                        _onSelectSection(
                          item.section,
                          featureGate: item.featureGate,
                        );
                      },
                      onSettingsTap: _showChartConfigDialog,
                      onConnectionSettingsTap: _showConnectionSettingsDialog,
                      onLogoutTap: () async {
                        await ref.read(adminAuthProvider.notifier).logout();
                      },
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 小螢幕沒有 Sidebar，仍提供左下角快速切換主題。
      floatingActionButton: useRail
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!useCompactBottomNav) ...[
                  FloatingActionButton.small(
                    heroTag: 'connection-settings',
                    onPressed: _showConnectionSettingsDialog,
                    tooltip: '連線設定',
                    elevation: 0,
                    backgroundColor: context.colorScheme.surface,
                    foregroundColor: context.colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.colorScheme.outlineVariant),
                    ),
                    child: const Icon(Icons.settings_ethernet),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'chart-settings',
                    onPressed: _showChartConfigDialog,
                    tooltip: 'Chart Settings',
                    elevation: 0,
                    backgroundColor: context.colorScheme.surface,
                    foregroundColor: context.colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.colorScheme.outlineVariant),
                    ),
                    child: const Icon(Icons.tune),
                  ),
                  const SizedBox(height: 10),
                ],
                FloatingActionButton.small(
                  heroTag: 'theme-toggle',
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                  tooltip: '切換主題',
                  elevation: 0,
                  backgroundColor: context.colorScheme.surface,
                  foregroundColor: context.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    ref.watch(themeModeProvider) == ThemeMode.light
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      // 小螢幕時使用底部導覽列
      bottomNavigationBar: useRail
          ? null
          : useCompactBottomNav
              ? NavigationBar(
                  selectedIndex: selectedIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) async {
                    if (index >= compactSections.length) {
                      await _showMoreSheet();
                      return;
                    }
                    final section = compactSections[index];
                    final item = _navItems.firstWhere(
                      (it) => it.section == section,
                    );
                    _onSelectSection(section, featureGate: item.featureGate);
                  },
                  destinations: [
                    for (final section in compactSections)
                      () {
                        final item = _navItems.firstWhere(
                          (it) => it.section == section,
                        );
                        return NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.bottomLabel,
                        );
                      }(),
                    const NavigationDestination(
                      icon: Icon(Icons.more_horiz),
                      selectedIcon: Icon(Icons.more_horiz),
                      label: '更多',
                    ),
                  ],
                )
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) {
                    final item = _navItems[index];
                    _onSelectSection(item.section, featureGate: item.featureGate);
                  },
                  destinations: _bottomDestinations,
                ),
    );
  }
}

class _DashboardNavItem {
  const _DashboardNavItem({
    required this.section,
    required this.icon,
    required this.selectedIcon,
    required this.sidebarLabel,
    required this.bottomLabel,
    required this.sidebarGroup,
    this.featureGate,
  });

  final _DashboardSection section;
  final IconData icon;
  final IconData selectedIcon;
  final String sidebarLabel;
  final String bottomLabel;
  final String sidebarGroup;

  /// 若不為 null，代表此導覽項目需要套用 feature gate。
  final DashboardFeature? featureGate;
}

/// 單一真相來源：導覽順序 / icon / 文案 / 可用性 gate 都在這裡集中維護。
const List<_DashboardNavItem> _navItems = [
  _DashboardNavItem(
    section: _DashboardSection.analysis,
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics,
    sidebarLabel: '分析總覽',
    bottomLabel: '分析',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.perLapOffset,
    icon: Icons.waves_outlined,
    selectedIcon: Icons.waves,
    sidebarLabel: '偏移分析',
    bottomLabel: '偏移分析',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.speedHeatmap,
    icon: Icons.local_fire_department_outlined,
    selectedIcon: Icons.local_fire_department,
    sidebarLabel: '速度熱圖',
    bottomLabel: '速度熱圖',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.swingHeatmap,
    icon: Icons.view_quilt_outlined,
    selectedIcon: Icons.view_quilt,
    sidebarLabel: '步態熱圖',
    bottomLabel: '步態熱圖',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.trajectoryPlayback,
    icon: Icons.movie_filter_outlined,
    selectedIcon: Icons.movie_filter,
    sidebarLabel: '軌跡影片',
    bottomLabel: '軌跡影片',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.videoPlayback,
    icon: Icons.play_circle_outline,
    selectedIcon: Icons.play_circle,
    sidebarLabel: '影片播放',
    bottomLabel: '影片',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.frequency,
    icon: Icons.ssid_chart_outlined,
    selectedIcon: Icons.ssid_chart,
    sidebarLabel: '頻譜分析',
    bottomLabel: '頻譜分析',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.yHeightDiff,
    icon: Icons.auto_graph,
    selectedIcon: Icons.auto_graph,
    sidebarLabel: '高度差',
    bottomLabel: '高度差',
    sidebarGroup: '分析',
  ),
  _DashboardNavItem(
    section: _DashboardSection.extraction,
    icon: Icons.construction_outlined,
    selectedIcon: Icons.construction,
    sidebarLabel: '資料提取',
    bottomLabel: '資料提取',
    sidebarGroup: '工具',
    featureGate: DashboardFeature.extraction,
  ),
  _DashboardNavItem(
    section: _DashboardSection.apkDownloads,
    icon: Icons.android_outlined,
    selectedIcon: Icons.android,
    sidebarLabel: '安裝包下載',
    bottomLabel: '下載',
    sidebarGroup: '工具',
  ),
  _DashboardNavItem(
    section: _DashboardSection.users,
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt,
    sidebarLabel: '使用者',
    bottomLabel: '使用者',
    sidebarGroup: '管理',
  ),
  _DashboardNavItem(
    section: _DashboardSection.admins,
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
    sidebarLabel: '管理員',
    bottomLabel: '管理員',
    sidebarGroup: '管理',
  ),
];

// 側邊導覽列的導覽項目
final List<SidebarDestination> _sidebarDestinations =
    _navItems
        .map(
          (item) => SidebarDestination(
            icon: item.icon,
            label: item.sidebarLabel,
            groupLabel: item.sidebarGroup,
          ),
        )
        .toList(growable: false);

// 底部導覽列的導覽項目
final List<NavigationDestination> _bottomDestinations =
    _navItems
        .map(
          (item) => NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.bottomLabel,
          ),
        )
        .toList(growable: false);