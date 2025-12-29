import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'test_helpers/fake_admin_auth_notifier.dart';

void main() {
  testWidgets('手機窄寬度切換主要頁面不應出現 RenderFlex overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        adminAuthProvider.overrideWith(FakeAdminAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(adminAuthProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GaitChartsApp(),
      ),
    );
    await tester.pumpAndSettle();

    final navBar = find.byType(NavigationBar);
    expect(navBar, findsOneWidget);

    // 切到「步態熱圖」(swingHeatmap) icon: Icons.view_quilt_outlined
    await tester.tap(
      find.descendant(
        of: navBar,
        matching: find.byIcon(Icons.view_quilt_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 切到「速度熱圖」icon: Icons.local_fire_department_outlined
    await tester.tap(
      find.descendant(
        of: navBar,
        matching: find.byIcon(Icons.local_fire_department_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}


