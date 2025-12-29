import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/core/widgets/async_error_view.dart';
import 'package:gait_charts/core/widgets/async_loading_view.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/views/admin_login_view.dart';
import 'package:gait_charts/features/dashboard/presentation/dashboard_screen.dart';

/// 根據管理員登入狀態切換 Login / Dashboard。
class AdminAuthGate extends ConsumerWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);

    return auth.when(
      data: (session) {
        // 如果登入失敗，則顯示登入畫面
        if (session == null) {
          return const AdminLoginView();
        }
        // 如果登入成功，則顯示儀表板
        return const DashboardScreen();
      },
      loading: () => const AsyncLoadingView(label: '正在檢查登入狀態...'),
      error: (error, stackTrace) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(adminAuthProvider),
      ),
    );
  }
}
