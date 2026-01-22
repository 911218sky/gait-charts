import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 儲存目前作用中的 Session 名稱。
final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, String>(
  ActiveSessionNotifier.new,
);

/// 控制 active session state 的 Notifier。
class ActiveSessionNotifier extends Notifier<String> {
  @override
  String build() => '';

  /// 設定新的 session 名稱。
  ///
  /// 若與當前值相同則不更新，避免不必要地重新觸發所有依賴該 session 的 API 請求。
  void setSession(String value) {
    if (state == value) {
      return;
    }
    state = value;
  }

  void clear() => state = '';
}

/// 儲存目前選取的圈數索引。
final selectedLapIndexProvider =
    NotifierProvider<SelectedLapIndexNotifier, int?>(
      SelectedLapIndexNotifier.new,
    );

/// 控制圈數選取狀態的 Notifier。
class SelectedLapIndexNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// 更新目前選中的圈數索引。
  void select(int? lapIndex) {
    state = lapIndex;
  }
}
