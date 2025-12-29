import 'package:flutter/foundation.dart';
import 'package:gait_charts/core/platform/platform_env.dart';

/// Dashboard 內可被「平台/環境」限制的功能清單。
///
/// 把 feature gate 變成 enum 的好處：
/// - 後續要新增「某功能只給桌面」時，規則集中在同一處。
/// - UI 不需要散落 `if (kIsWeb || isMobile) ...` 這種判斷。
enum DashboardFeature {
  extraction, // 資料提取
  extractionLocalBag, // 本機 bag 檔案選取/上傳（僅桌面）
}

/// Dashboard 功能可用性（Feature Availability）判斷器。
///
/// 這裡只負責回傳「是否被限制」與「要顯示的文案」，不碰任何 UI 元件。
@immutable
class DashboardFeatureAvailability {
  const DashboardFeatureAvailability();

  /// 回傳 `null` 表示可用；回傳字串表示被限制時要提示使用者的訊息。
  ///
  /// 設計上讓 UI 只需要：
  /// - 取得 `PlatformEnv`
  /// - 呼叫這個方法拿到 message
  /// - 若 message != null，顯示 toast/snackbar 並中止導覽
  String? blockedMessage({
    required DashboardFeature feature,
    required PlatformEnv env,
  }) {
    switch (feature) {
      case DashboardFeature.extraction:
        // 已改為「從伺服器清單選 bag」＋ `bag_id` 觸發提取，不再依賴本機檔案挑選。
        // 因此 Web / 手機 / 桌面皆可用。
        return null;
      case DashboardFeature.extractionLocalBag:
        // 本機檔案選取（或上傳）目前僅開放桌面版（Windows/macOS/Linux）。
        if (env.isWeb) {
          return '本機檔案上傳/選取暫未開放給網頁版，請使用桌面版 App';
        }
        if (env.isMobile) {
          return '本機檔案上傳/選取暫未開放給手機版，請使用桌面版 App';
        }
        return null;
    }
  }
}


