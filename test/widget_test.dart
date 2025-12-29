// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'test_helpers/fake_admin_auth_notifier.dart';

void main() {
  testWidgets('Dashboard renders header', (tester) async {
    final response = StageDurationsResponse(
      laps: [
        LapSummary(
          lapIndex: 1,
          startTimestampSeconds: 0,
          endTimestampSeconds: 32.5,
          totalDurationSeconds: 32.5,
          totalDistanceMeters: 15.3,
          stages: const [
            StageDurationStage(label: '1 Stand up', durationSeconds: 5.2),
            StageDurationStage(label: '2 Walk to cone', durationSeconds: 8.1),
            StageDurationStage(label: '3 Turn at cone', durationSeconds: 4.4),
            StageDurationStage(label: '4 Walk back', durationSeconds: 9.3),
            StageDurationStage(label: '5 Align to sit', durationSeconds: 3.2),
            StageDurationStage(label: '6 Sit down', durationSeconds: 2.3),
          ],
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        // 模擬已登入，避免卡在 AdminAuthGate 的登入頁而找不到 dashboard header。
        adminAuthProvider.overrideWith(FakeAdminAuthNotifier.new),
        stageDurationsProvider.overrideWith((ref) async => response),
      ],
    );
    addTearDown(container.dispose);
    // 預熱：確保 AdminAuthGate 進入畫面時已經是 data(session) 狀態。
    await container.read(adminAuthProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GaitChartsApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.textContaining('Rehabilitation Session Analyzer'),
      findsOneWidget,
    );
  });
}
