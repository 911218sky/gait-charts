import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

void main() {
  test('decodeTrajectoryPayload: base64+zlib+u16 little-endian decode ok', () {
    // bounds: 0..1，方便驗證反量化
    const nFrames = 2;

    // 兩幀：
    // k=0: L=(0,0), R=(1,1)
    // k=1: L=(0.5, 0.25), R=(0.25, 0.5)
    final bytes = Uint8List(nFrames * 4 * 2);
    final bd = ByteData.sublistView(bytes);

    void setFrame(int k, int xL, int yL, int xR, int yR) {
      final base = k * 8;
      bd.setUint16(base + 0, xL, Endian.little);
      bd.setUint16(base + 2, yL, Endian.little);
      bd.setUint16(base + 4, xR, Endian.little);
      bd.setUint16(base + 6, yR, Endian.little);
    }

    setFrame(0, 0, 0, 65535, 65535);
    setFrame(1, 32768, 16384, 16384, 32768);

    final compressed = const ZLibEncoder().encode(bytes);
    final b64 = base64Encode(Uint8List.fromList(compressed));

    final json = <String, dynamic>{
      'meta': {
        'projection': 'xz',
        'fps_out': 24,
        'rotate_180': true,
        'bounds': {'xmin': 0.0, 'xmax': 1.0, 'ymin': 0.0, 'ymax': 1.0},
        'encoding': 'u16_xy_lr_zlib_b64',
        'endian': 'little',
        'n_frames': nFrames,
      },
      'scene': {
        'chair_xy_u16': [0, 0],
        'cone_xy_u16': [65535, 65535],
        'r_chair': 0.3,
        'r_cone': 0.2,
      },
      'frames': {'xy_lr_u16_zlib_b64': b64},
      'laps': <Map<String, dynamic>>[],
    };

    final response = TrajectoryPayloadResponse.fromJson(json);
    final decoded = decodeTrajectoryPayload(response);

    expect(decoded.nFrames, nFrames);
    expect(decoded.leftXy.length, nFrames * 2);
    expect(decoded.rightXy.length, nFrames * 2);
    expect(decoded.centerXy.length, nFrames * 2);

    // k=0
    expect(decoded.leftXy[0], closeTo(0.0, 1e-6));
    expect(decoded.leftXy[1], closeTo(0.0, 1e-6));
    expect(decoded.rightXy[0], closeTo(1.0, 1e-6));
    expect(decoded.rightXy[1], closeTo(1.0, 1e-6));
    expect(decoded.centerXy[0], closeTo(0.5, 1e-6));
    expect(decoded.centerXy[1], closeTo(0.5, 1e-6));

    // k=1：因為 u16/65535 不是精準 0.5，容許誤差稍大
    expect(decoded.leftXy[2], closeTo(32768 / 65535.0, 1e-4));
    expect(decoded.leftXy[3], closeTo(16384 / 65535.0, 1e-4));
    expect(decoded.rightXy[2], closeTo(16384 / 65535.0, 1e-4));
    expect(decoded.rightXy[3], closeTo(32768 / 65535.0, 1e-4));
  });

  test('decodeTrajectoryPayload: length mismatch throws FormatException', () {
    final json = <String, dynamic>{
      'meta': {
        'projection': 'xz',
        'fps_out': 24,
        'rotate_180': true,
        'bounds': {'xmin': 0.0, 'xmax': 1.0, 'ymin': 0.0, 'ymax': 1.0},
        'encoding': 'u16_xy_lr_zlib_b64',
        'endian': 'little',
        'n_frames': 2,
      },
      'scene': {
        'chair_xy_u16': [0, 0],
        'cone_xy_u16': [0, 0],
        'r_chair': 0.3,
        'r_cone': 0.2,
      },
      // 空 bytes 會觸發格式錯誤
      'frames': {'xy_lr_u16_zlib_b64': base64Encode(const <int>[])},
      'laps': <Map<String, dynamic>>[],
    };

    final response = TrajectoryPayloadResponse.fromJson(json);
    expect(() => decodeTrajectoryPayload(response), throwsFormatException);
  });
}


