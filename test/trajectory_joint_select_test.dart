import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/trajectory/trajectory_config_panel.dart';

void main() {
  testWidgets('Trajectory 設定：可選 left/right joint 與 preset', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: const SizedBox(
              height: 800,
              child: TrajectoryConfigPanel(
                width: null,
                showSidebarBorder: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 預設值（domain 預設目前是字串 L_HIP/R_HIP；UI 會顯示映射後的 index）
    expect(container.read(trajectoryPayloadConfigProvider).leftJoint, 'L_HIP');
    expect(container.read(trajectoryPayloadConfigProvider).rightJoint, 'R_HIP');

    // 直接選擇左踝 (27)
    final leftSelect = find.byTooltip('左側關節 (left_joint)');
    expect(leftSelect, findsOneWidget);
    await tester.tap(leftSelect);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('27 –'));
    await tester.pumpAndSettle();
    expect(container.read(trajectoryPayloadConfigProvider).leftJoint, 27);

    // 用 preset 一鍵套用踝 (27/28)
    await tester.tap(find.text('踝 (27/28)'));
    await tester.pumpAndSettle();

    final config = container.read(trajectoryPayloadConfigProvider);
    expect(config.leftJoint, 27);
    expect(config.rightJoint, 28);
    expect(tester.takeException(), isNull);
  });
}


