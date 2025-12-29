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
  return <String, dynamic>{'f32_zlib_b64': b64, 'endian': 'little', 'n': values.length};
}

void main() {
  test('FloatArrayF32ZlibB64: decodeToDoubles ok', () {
    final values = <double>[0.0, 1.5, -2.25, 1000.0];
    final payload = _makeF32ZlibB64Payload(values);
    final parsed = FloatArrayF32ZlibB64.fromJson(payload);

    final decoded = parsed.decodeToDoubles();
    expect(decoded.length, values.length);
    for (var i = 0; i < values.length; i++) {
      expect(decoded[i], closeTo(values[i], 1e-6));
    }
  });

  test('YHeightDiffResponse.fromJson: reads *_f32_zlib_b64', () {
    final json = <String, dynamic>{
      'time_s_f32_zlib_b64': _makeF32ZlibB64Payload([0.0, 0.5, 1.0]),
      'left_f32_zlib_b64': _makeF32ZlibB64Payload([1.0, 2.0, 3.0]),
      'right_f32_zlib_b64': _makeF32ZlibB64Payload([1.5, 2.5, 3.5]),
      'diff_f32_zlib_b64': _makeF32ZlibB64Payload([-0.5, -0.5, -0.5]),
      'left_joint': 29,
      'right_joint': 30,
    };

    final res = YHeightDiffResponse.fromJson(json);
    expect(res.timeSeconds, [0.0, 0.5, 1.0]);
    expect(res.left, [1.0, 2.0, 3.0]);
    expect(res.right, [1.5, 2.5, 3.5]);
    expect(res.diff, [-0.5, -0.5, -0.5]);
    expect(res.leftJoint, 29);
    expect(res.rightJoint, 30);
  });

  test('MultiFftSeriesResponse.fromJson: reads *_f32_zlib_b64', () {
    final json = <String, dynamic>{
      'component': 'z',
      'series': [
        {
          'joint_spec': [27, 28],
          'freq_hz_f32_zlib_b64': _makeF32ZlibB64Payload([0.1, 0.2, 0.3]),
          'psd_db_f32_zlib_b64': _makeF32ZlibB64Payload([-10.0, -20.0, -30.0]),
          'peaks': [
            {'freq_hz': 0.2, 'db': -20.0},
          ],
        },
      ],
    };

    final res = MultiFftSeriesResponse.fromJson(json);
    expect(res.component, 'z');
    expect(res.series.length, 1);
    final freq = res.series.first.frequencyHz;
    expect(freq.length, 3);
    expect(freq[0], closeTo(0.1, 1e-6));
    expect(freq[1], closeTo(0.2, 1e-6));
    expect(freq[2], closeTo(0.3, 1e-6));

    final psd = res.series.first.psdDb;
    expect(psd.length, 3);
    expect(psd[0], closeTo(-10.0, 1e-6));
    expect(psd[1], closeTo(-20.0, 1e-6));
    expect(psd[2], closeTo(-30.0, 1e-6));
    expect(res.series.first.peaks.length, 1);
    expect(res.series.first.peaks.first.freqHz, closeTo(0.2, 1e-6));
    expect(res.series.first.peaks.first.db, closeTo(-20.0, 1e-6));
  });

  test('SpatialSpectrumResponse.fromJson: reads freq_f32_zlib_b64/psd_db_f32_zlib_b64', () {
    final json = <String, dynamic>{
      'spectrums': [
        {
          'pair': 'xz',
          'freq_f32_zlib_b64': _makeF32ZlibB64Payload([0.5, 1.0, 1.5]),
          'psd_db_f32_zlib_b64': _makeF32ZlibB64Payload([-3.0, -10.0, -20.0]),
          'peaks': [
            {'freq': 1.0, 'db': -10.0},
          ],
        },
      ],
    };

    final res = SpatialSpectrumResponse.fromJson(json);
    expect(res.series.length, 1);
    expect(res.series.first.pair, 'xz');
    final f = res.series.first.frequencyHz;
    expect(f.length, 3);
    expect(f[0], closeTo(0.5, 1e-6));
    expect(f[1], closeTo(1.0, 1e-6));
    expect(f[2], closeTo(1.5, 1e-6));
    final db = res.series.first.psdDb;
    expect(db.length, 3);
    expect(db[0], closeTo(-3.0, 1e-6));
    expect(db[1], closeTo(-10.0, 1e-6));
    expect(db[2], closeTo(-20.0, 1e-6));
    expect(res.series.first.peaks.length, 1);
    expect(res.series.first.peaks.first.freqHz, closeTo(1.0, 1e-6));
    expect(res.series.first.peaks.first.db, closeTo(-10.0, 1e-6));
  });
}


