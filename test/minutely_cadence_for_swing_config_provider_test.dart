import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/presentation/providers/analysis/minutely_cadence_state.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/analysis/swing_info_heatmap_state.dart';

void main() {
  test(
    'minutelyCadenceBarsForSwingConfigProvider 不應因 Swing 色階(vminPct/vmaxPct)變更而更新',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final updates = <Object?>[];

      final sub = container.listen(
        minutelyCadenceBarsForSwingConfigProvider,
        (prev, next) => updates.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final before = container.read(minutelyCadenceBarsForSwingConfigProvider);

      // 只改 Swing 熱圖的色階（視覺化用），不應影響 minutely config provider。
      final swingNotifier = container.read(swingInfoHeatmapConfigProvider.notifier);
      swingNotifier.updateVminPct(33.0);
      swingNotifier.updateVmaxPct(44.0);
      swingNotifier.useAutoColorRange(); // 清回 auto（null）

      final after = container.read(minutelyCadenceBarsForSwingConfigProvider);

      expect(after.toJson(), before.toJson());
      expect(updates.length, 1); // 只 fireImmediately 那次
    },
  );
}


