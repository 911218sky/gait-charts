import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 是否啟用自訂無邊框標題列。
///
/// - 優先讀取環境變數 `USE_GAIT_CHARTS_TITLE_BAR` (true/false)。
/// - 若未設定環境變數，則預設為 `false`。
bool get kShowCustomTitleBar {
  final env = Platform.environment['USE_GAIT_CHARTS_TITLE_BAR'];
  if (env == null) return false;
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return false;
  return env.toLowerCase() == 'true';
}

/// 初始化桌面視窗設定
Future<void> initDesktopWindow() async {
  if (!kShowCustomTitleBar) {
    return;
  }

  await windowManager.ensureInitialized();

  // 目標：移除 Windows 預設 title bar（你看到的上面那條），改由 App 內自訂。
  const windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
    center: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 設置為無邊框視窗
    await windowManager.setAsFrameless();
    // 顯示視窗
    await windowManager.show();
    // 聚焦視窗
    await windowManager.focus();
  });
}
