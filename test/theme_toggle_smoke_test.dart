import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'test_helpers/fake_app_config_storage.dart';

class _FakeAdminAuthNotifier extends AdminAuthNotifier {
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

void main() {
  testWidgets('切換主題不應觸發 TextStyle.lerp/GlobalKey 相關例外', (tester) async {
    // 確保走小螢幕 Layout（會顯示底部 NavigationBar + 左下角切換主題 FAB）
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        // 模擬已登入，避免卡在 AdminAuthGate 的登入頁而找不到 dashboard 導覽項目。
        adminAuthProvider.overrideWith(_FakeAdminAuthNotifier.new),
        appConfigStorageProvider.overrideWithValue(FakeAppConfigStorage()),
        // 讓 swing view 的 heatmap request 直接回空，避免後端依賴。
        swingInfoHeatmapProvider.overrideWith((ref) async {
          return const SwingInfoHeatmapResponse(
            minutes: [1],
            swingPct: [
              [0.42],
              [0.41],
            ],
            swingSeconds: [
              [0.52],
              [0.50],
            ],
          );
        }),
        // 讓 MinutelyCadenceBarsCard 一定會被 build（它曾是 crash 的第一個炸點）。
        minutelyCadenceBarsForSwingProvider.overrideWith((ref) async {
          return const MinutelyCadenceStepLengthBarsResponse(
            minutes: [1, 2],
            cadenceSpm: [102, 98],
            stepLengthMeters: [0.62, 0.60],
            stepCounts: [110, 105],
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    // 預熱：確保 AdminAuthGate 進入畫面時已經是 data(session) 狀態。
    await container.read(appConfigAsyncProvider.future);
    await container.read(adminAuthProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GaitChartsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 切到「步態熱圖」頁（MinutelyCadenceBarsCard 在這頁面內）
    await tester.tap(find.byIcon(Icons.view_quilt_outlined));
    await tester.pump(const Duration(milliseconds: 300));

    // 切換主題（過去這裡會爆：Failed to interpolate TextStyles with different inherit values）
    await tester.tap(find.byTooltip('切換主題'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 任何 framework exception 都會被 WidgetTester 收集起來
    expect(tester.takeException(), isNull);
  });
}


