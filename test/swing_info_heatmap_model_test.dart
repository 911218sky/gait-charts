import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

void main() {
  test('SwingInfoHeatmapResponse.fromJson: parses 2xN matrices', () {
    final json = <String, dynamic>{
      'minutes': [1, 2, 3],
      'swing_pct': [
        [10, 20, 30],
        [40, 50, 60],
      ],
      'swing_s': [
        [0.2, 0.25, 0.3],
        [0.21, 0.24, 0.29],
      ],
    };

    final res = SwingInfoHeatmapResponse.fromJson(json);
    expect(res.minutes, [1, 2, 3]);
    expect(res.minutesCount, 3);
    expect(res.swingPct.length, 2);
    expect(res.swingPct[0], [10.0, 20.0, 30.0]);
    expect(res.swingPct[1], [40.0, 50.0, 60.0]);
    expect(res.swingSeconds[0], [0.2, 0.25, 0.3]);
    expect(res.swingSeconds[1], [0.21, 0.24, 0.29]);
  });

  test('SwingInfoHeatmapResponse.fromJson: pads rows to expected cols', () {
    final json = <String, dynamic>{
      'minutes': [1, 2, 3],
      'swing_pct': [
        [10, 20],
        [40, 50],
      ],
      'swing_s': [
        [0.2],
      ],
    };

    final res = SwingInfoHeatmapResponse.fromJson(json);

    expect(res.swingPct, [
      [10.0, 20.0, null],
      [40.0, 50.0, null],
    ]);

    // swing_s 只給一列，應補齊 2 列並對齊 minutes 長度
    expect(res.swingSeconds, [
      [0.2, null, null],
      [null, null, null],
    ]);
  });
}


