import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';

/// 讓 widget tests 可以直接進入 Dashboard（略過 AdminAuthGate 的登入頁）。
class FakeAdminAuthNotifier extends AdminAuthNotifier {
  @override
  Future<AuthSession?> build() async {
    return AuthSession(
      token: 'test-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      admin: AdminPublic(
        adminCode: 'test-admin',
        username: 'test',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }
}


