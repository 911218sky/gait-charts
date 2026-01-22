import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/platform/window_manager_initializer.dart';
import 'package:gait_charts/core/storage/theme_mode_storage.dart';
import 'package:gait_charts/features/admin/presentation/views/admin_auth_gate.dart';

/// 應用程式 root widget，注入全域主題並載入儀表板畫面。
class GaitChartsApp extends ConsumerWidget {
  const GaitChartsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 監聽應用程式主題設定
    final theme = ref.watch(appThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Realsense Pose Dashboard',
      debugShowCheckedModeBanner: false, // 隱藏 debug 標籤
      theme: theme.light, // 淺色主題
      darkTheme: theme.dark, // 深色主題
      themeMode: themeMode, // 使用 Provider 控制的主題模式
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();

        // 只在 Windows 的無邊框模式套用整體圓角裁切。
        if (!kShowCustomTitleBar) {
          return content;
        }

        final colors = context.colorScheme;
        const radius = 14.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ColoredBox(
            color: colors.surface,
            child: content,
          ),
        );
      },
      // 先走登入，再進入儀表板
      home: const AdminAuthGate(),
    );
  }
}

/// 控制目前主題模式的 Notifier。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeStorage get _storage => ref.read(themeModeStorageProvider);

  @override
  ThemeMode build() {
    // 預設深色；再從本機偏好設定讀回使用者最後選擇的模式。
    unawaited(_restore());
    return ThemeMode.dark;
  }

  Future<void> _restore() async {
    try {
      // 從本機儲存中讀取主題模式
      final saved = await _storage.readThemeMode();
      if (!ref.mounted || saved == null) {
        return;
      }
      state = saved;
    } catch (_) {
      // 讀取失敗就維持預設，不影響啟動。
    }
  }

  /// 直接設定為指定的主題模式。
  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(_storage.writeThemeMode(mode));
  }

  /// 切換淺 / 深色模式。
  void toggle() {
    setThemeMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

/// 主題模式的本機儲存層 Provider。
final themeModeStorageProvider = Provider<ThemeModeStorage>((ref) {
  return ThemeModeStorage();
});

/// 供 UI 監聽的主題模式 Provider。
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// 封裝淺色與深色主題資料，維持設定一致性。
class AppThemeBundle {
  const AppThemeBundle({required this.light, required this.dark});

  final ThemeData light;
  final ThemeData dark;
}

/// 產生 app 共用主題的 Provider。
final appThemeProvider = Provider<AppThemeBundle>((ref) {
  return AppThemeBundle(light: buildLightTheme(), dark: buildDarkTheme());
});
