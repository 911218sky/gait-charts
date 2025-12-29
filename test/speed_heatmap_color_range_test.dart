import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/analysis/speed_heatmap_state.dart';

void main() {
  group('SpeedHeatmapConfig', () {
    test('toJson: 不應包含 vmin/vmax（API 不收）', () {
      const config = SpeedHeatmapConfig();

      final json = config.toJson();

      expect(json.containsKey('vmin'), isFalse);
      expect(json.containsKey('vmax'), isFalse);
    });
  });

  group('SpeedHeatmapColorRangeNotifier', () {
    test('useAutoRange 會把 vmin/vmax 變成 null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(speedHeatmapColorRangeProvider.notifier);
      final before = container.read(speedHeatmapColorRangeProvider);
      expect(before.vmin, isNotNull);
      expect(before.vmax, isNotNull);

      notifier.useAutoRange();

      final after = container.read(speedHeatmapColorRangeProvider);
      expect(after.vmin, isNull);
      expect(after.vmax, isNull);
    });

    test('updateVmin/updateVmax 可從 Auto 回到手動色階', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(speedHeatmapColorRangeProvider.notifier);
      notifier.useAutoRange();
      notifier.updateVmin(0.5);
      notifier.updateVmax(4.2);

      final range = container.read(speedHeatmapColorRangeProvider);
      expect(range.vmin, 0.5);
      expect(range.vmax, 4.2);
    });
  });
}


