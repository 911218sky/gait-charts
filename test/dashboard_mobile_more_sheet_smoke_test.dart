import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'test_helpers/fake_admin_auth_notifier.dart';

void main() {
  testWidgets('手機寬度下顯示「更多」並可打開 BottomSheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
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

    // compact bottom nav 的最後一個 destination 是 Icons.more_horiz
    await tester.tap(
      find.descendant(of: navBar, matching: find.byIcon(Icons.more_horiz)),
    );
    await tester.pumpAndSettle();

    // BottomSheet 內會出現「頁面」段落（在上半部，不需要捲動）
    expect(find.text('頁面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}


