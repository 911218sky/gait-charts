import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/platform/window_manager_initializer.dart';

/// 應用程式進入點，完成 Flutter 綁定並啟動 Riverpod 環境。
Future<void> main() async {
  // 確保 Flutter 綁定初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 桌面端（Windows、macOS、Linux）初始化無邊框視窗
  await initDesktopWindow();
  // 啟動應用程式，並包覆在 ProviderScope 中以使用 Riverpod 狀態管理
  runApp(const ProviderScope(child: GaitChartsApp()));
}
