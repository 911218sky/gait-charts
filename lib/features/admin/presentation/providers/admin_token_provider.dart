import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 簡單的 token 狀態，供 Dio 注入 Authorization 使用。
/// 不依賴 repository/ApiService，避免循環引用。
class AdminTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String? token) {
    state = token;
  }
}

final adminTokenStateProvider =
    NotifierProvider<AdminTokenNotifier, String?>(
  AdminTokenNotifier.new,
);

