import 'package:flutter/foundation.dart';

/// 目前執行環境的「平台資訊」快照。
///
/// 這個類別的目的是把 `kIsWeb` / `defaultTargetPlatform` 之類的分散判斷集中起來，
/// 讓 feature 的可用性規則可以在 domain 層以純 Dart 方式被測試與維護。
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

  /// 讀取「目前執行環境」的預設值。
  ///
  /// 注意：在 Web 上 `defaultTargetPlatform` 可能是其他值，因此以 `kIsWeb` 作為主要判斷。
  factory PlatformEnv.current() => PlatformEnv(
    isWeb: kIsWeb,
    targetPlatform: defaultTargetPlatform,
  );
}


