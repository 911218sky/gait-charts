import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

Uint8List _packF32Le(List<double> values) {
  final bytes = Uint8List(values.length * 4);
  final bd = ByteData.sublistView(bytes);
  for (var i = 0; i < values.length; i++) {
    bd.setFloat32(i * 4, values[i].toDouble(), Endian.little);
  }
  return bytes;
}

Map<String, dynamic> _makeF32ZlibB64Payload(List<double> values) {
  final raw = _packF32Le(values);
  final compressed = const ZLibEncoder().encode(raw);
  final b64 = base64Encode(Uint8List.fromList(compressed));
  return <String, dynamic>{
    'f32_zlib_b64': b64,
    'endian': 'little',
    'n': values.length,
  };
}

void main() {
  test('PerLapOffsetResponse.fromJson: reads lap series *_f32_zlib_b64 + FFT *_f32_zlib_b64', () {
    final json = <String, dynamic>{
      'laps': [
        {
          'lap_index': 1,
          // 新版 API：lap 內時間/序列皆為 float32+zlib+b64
          'time_s_f32_zlib_b64': _makeF32ZlibB64Payload([10.0, 11.0, 12.0]),
          'lat_raw_f32_zlib_b64': _makeF32ZlibB64Payload([0.1, 0.2, 0.3]),
          'lat_smooth_f32_zlib_b64': _makeF32ZlibB64Payload([0.11, 0.21, 0.31]),
          'theta_deg_f32_zlib_b64': _makeF32ZlibB64Payload([0.0, 5.0, 10.0]),
          'turn_regions': {
            'cone': {'start_idx': 0, 'end_idx': 1},
            'chair': {'start_idx': 1, 'end_idx': 2},
          },
          'walk_region': {'start_idx': 0, 'end_idx': 2},
          'fft': {
            'band': [0.0, 2.0],
            'freq_hz_f32_zlib_b64': _makeF32ZlibB64Payload([0.1, 0.2, 0.3]),
            'psd_db_f32_zlib_b64': _makeF32ZlibB64Payload([-10.0, -20.0, -30.0]),
            'peak_freq_hz': 0.2,
            'peak_power': 1.0,
            'peak_db': -20.0,
          },
        },
      ],
    };

    final res = PerLapOffsetResponse.fromJson(json);
    expect(res.laps.length, 1);

    final lap = res.laps.first;
    expect(lap.lapIndex, 1);
    // 會 normalize 到 0 起點
    expect(lap.timeSeconds, [0.0, 1.0, 2.0]);
    // float32 會有些微精度誤差，避免用完全相等比對
    expect(lap.latRaw.length, 3);
    expect(lap.latRaw[0], closeTo(0.1, 1e-6));
    expect(lap.latRaw[1], closeTo(0.2, 1e-6));
    expect(lap.latRaw[2], closeTo(0.3, 1e-6));
    expect(lap.latSmooth.length, 3);
    expect(lap.latSmooth[0], closeTo(0.11, 1e-6));
    expect(lap.latSmooth[1], closeTo(0.21, 1e-6));
    expect(lap.latSmooth[2], closeTo(0.31, 1e-6));
    expect(lap.thetaDegrees.length, 3);
    expect(lap.thetaDegrees[0], closeTo(0.0, 1e-6));
    expect(lap.thetaDegrees[1], closeTo(5.0, 1e-6));
    expect(lap.thetaDegrees[2], closeTo(10.0, 1e-6));
    expect(lap.fft.band, [0.0, 2.0]);

    final freq = lap.fft.frequencyHz;
    expect(freq.length, 3);
    expect(freq[0], closeTo(0.1, 1e-6));
    expect(freq[1], closeTo(0.2, 1e-6));
    expect(freq[2], closeTo(0.3, 1e-6));

    final psd = lap.fft.psdDb;
    expect(psd.length, 3);
    expect(psd[0], closeTo(-10.0, 1e-6));
    expect(psd[1], closeTo(-20.0, 1e-6));
    expect(psd[2], closeTo(-30.0, 1e-6));

    expect(lap.fft.peakFrequencyOrNull, closeTo(0.2, 1e-6));
    expect(lap.fft.peakDbOrNull, closeTo(-20.0, 1e-6));
  });
}


