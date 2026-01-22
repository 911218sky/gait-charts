/// Web / 非 io 平台的 no-op（避免引入 dart:io 與 window_manager）。
/// 是否啟用自訂無邊框標題列（Web/手機一律 false）。
bool get kShowCustomTitleBar => false;

/// 初始化桌面視窗行為（Web/手機不做事）。
Future<void> initDesktopWindow() async {}