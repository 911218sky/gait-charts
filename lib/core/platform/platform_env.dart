import 'package:flutter/foundation.dart';

/// 目前執行環境的平台資訊快照。
/// 集中 kIsWeb / defaultTargetPlatform 判斷，讓 feature 可用性規則可在 domain 層測試。
@immutable
class PlatformEnv {
  const PlatformEnv({
    required this.isWeb,
    required this.targetPlatform,
  });

  /// 是否為 Web (Flutter Web)。
  final bool isWeb;

  /// Flutter 判斷的 target platform。
  final TargetPlatform targetPlatform;

  /// 是否為手機平台（Android/iOS）。
  bool get isMobile =>
      targetPlatform == TargetPlatform.android ||
      targetPlatform == TargetPlatform.iOS;

  /// 是否為桌面平台（Windows/macOS/Linux）。
  bool get isDesktop =>
      targetPlatform == TargetPlatform.windows ||
      targetPlatform == TargetPlatform.macOS ||
      targetPlatform == TargetPlatform.linux;

  /// 讀取目前執行環境。Web 上 defaultTargetPlatform 可能是其他值，以 kIsWeb 為主要判斷。
  factory PlatformEnv.current() => PlatformEnv(
    isWeb: kIsWeb,
    targetPlatform: defaultTargetPlatform,
  );
}


