import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/extraction/extraction_panel.dart';

void main() {
  testWidgets('Extraction 設定：max_frames/max_concurrency 可選擇並更新 provider', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              // ignore: prefer_const_literals_to_create_immutables
              children: [
                // ignore: prefer_const_constructors
                ExtractionPanel(
                  suggestedSession: 'demo_session',
                  onCompleted: _noopCompleted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 預設值
    expect(container.read(extractConfigProvider).maxFrames, 10800);
    expect(container.read(extractConfigProvider).maxConcurrency, 3);

    // 打開 max_frames 選單
    final maxFramesSelect = find.byTooltip('最大影格數 (max_frames)');
    expect(maxFramesSelect, findsOneWidget);
    await tester.tap(maxFramesSelect);
    await tester.pumpAndSettle();

    // 選擇另一個值
    await tester.tap(find.text('7200'));
    await tester.pumpAndSettle();

    expect(container.read(extractConfigProvider).maxFrames, 7200);

    // 打開 max_concurrency 選單並選 10
    final maxConcurrencySelect = find.byTooltip('最大並行處理數');
    expect(maxConcurrencySelect, findsOneWidget);
    await tester.tap(maxConcurrencySelect);
    await tester.pumpAndSettle();

    await tester.tap(find.text('10 個同時'));
    await tester.pumpAndSettle();

    expect(container.read(extractConfigProvider).maxConcurrency, 10);
    expect(tester.takeException(), isNull);
  });
}

void _noopCompleted(_) {}


