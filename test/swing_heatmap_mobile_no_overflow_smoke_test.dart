import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'test_helpers/fake_admin_auth_notifier.dart';
import 'test_helpers/fake_app_config_storage.dart';

void main() {
  testWidgets('手機寬度下 Swing 熱圖頁不應出現 RenderFlex overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        adminAuthProvider.overrideWith(FakeAdminAuthNotifier.new),
        appConfigStorageProvider.overrideWithValue(FakeAppConfigStorage()),
        swingInfoHeatmapProvider.overrideWith((ref) async {
          // minutes 稍多一點，確保 legend / 軸線等 UI 都會被 build。
          return const SwingInfoHeatmapResponse(
            minutes: [1, 2, 3, 4, 5, 6],
            swingPct: [
              [0.42, 0.41, 0.40, 0.43, 0.44, 0.39],
              [0.41, 0.40, 0.39, 0.42, 0.43, 0.38],
            ],
            swingSeconds: [
              [0.52, 0.50, 0.49, 0.53, 0.55, 0.48],
              [0.50, 0.49, 0.48, 0.52, 0.53, 0.47],
            ],
          );
        }),
        minutelyCadenceBarsForSwingProvider.overrideWith((ref) async {
          return const MinutelyCadenceStepLengthBarsResponse(
            minutes: [1, 2, 3, 4, 5, 6],
            cadenceSpm: [102, 98, 100, 101, 99, 97],
            stepLengthMeters: [0.62, 0.60, 0.61, 0.63, 0.60, 0.59],
            stepCounts: [110, 105, 108, 112, 104, 102],
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appConfigAsyncProvider.future);
    await container.read(adminAuthProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GaitChartsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 切到「步態熱圖」頁
    await tester.tap(find.byIcon(Icons.view_quilt_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('手機寬度下 Swing 熱圖可左右拖曳捲動分鐘軸', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        adminAuthProvider.overrideWith(FakeAdminAuthNotifier.new),
        appConfigStorageProvider.overrideWithValue(FakeAppConfigStorage()),
        swingInfoHeatmapProvider.overrideWith((ref) async {
          // minutes 稍多一點，確保水平可捲動（超過手機寬度）。
          return const SwingInfoHeatmapResponse(
            minutes: [1, 2, 3, 4, 5, 6],
            swingPct: [
              [0.42, 0.41, 0.40, 0.43, 0.44, 0.39],
              [0.41, 0.40, 0.39, 0.42, 0.43, 0.38],
            ],
            swingSeconds: [
              [0.52, 0.50, 0.49, 0.53, 0.55, 0.48],
              [0.50, 0.49, 0.48, 0.52, 0.53, 0.47],
            ],
          );
        }),
        minutelyCadenceBarsForSwingProvider.overrideWith((ref) async {
          return const MinutelyCadenceStepLengthBarsResponse(
            minutes: [1, 2, 3, 4, 5, 6],
            cadenceSpm: [102, 98, 100, 101, 99, 97],
            stepLengthMeters: [0.62, 0.60, 0.61, 0.63, 0.60, 0.59],
            stepCounts: [110, 105, 108, 112, 104, 102],
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appConfigAsyncProvider.future);
    await container.read(adminAuthProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GaitChartsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 切到「步態熱圖」頁
    await tester.tap(find.byIcon(Icons.view_quilt_outlined));
    await tester.pumpAndSettle();

    final hScrollView = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(hScrollView, findsOneWidget);

    final scrollableFinder =
        find.descendant(of: hScrollView, matching: find.byType(Scrollable));
    expect(scrollableFinder, findsOneWidget);

    final scrollableState = tester.state<ScrollableState>(scrollableFinder);
    final before = scrollableState.position.pixels;

    // 從「可見 viewport 內」起手拖曳，避免使用 CustomPaint 中心點（通常在螢幕外）。
    // 這裡刻意選在 label 右側的熱圖區域，符合「在格子上左右滑動」的使用情境。
    final viewportRect = tester.getRect(scrollableFinder);
    final start = Offset(viewportRect.left + 220, viewportRect.center.dy);
    await tester.dragFrom(start, const Offset(-220, 0));
    await tester.pumpAndSettle();

    final after = scrollableState.position.pixels;
    expect(after, greaterThan(before));
    expect(tester.takeException(), isNull);
  });
}


