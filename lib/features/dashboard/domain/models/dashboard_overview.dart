import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';

part 'stage_durations.dart';
part 'extraction_models.dart';
part 'fft_periodogram_params.dart';
part 'per_lap_offset.dart';
part 'minutely_cadence_step_length.dart';
part 'y_height_diff.dart';
part 'spatial_spectrum.dart';
part 'multi_fft_series.dart';
part 'speed_heatmap.dart';
part 'swing_info_heatmap.dart';
part 'trajectory_payload.dart';

/// 壓縮後的一維 float32 array（little-endian）：
/// - base64 decode
/// - zlib 解壓
/// - 以 float32 little-endian 解碼
class FloatArrayF32ZlibB64 {
  const FloatArrayF32ZlibB64({
    required this.f32ZlibB64,
    required this.endian,
    required this.n,
  });

  final String f32ZlibB64;
  final String endian;
  final int n;

  factory FloatArrayF32ZlibB64.fromJson(Map<String, dynamic> json) {
    return FloatArrayF32ZlibB64(
      f32ZlibB64: _stringValue(json['f32_zlib_b64']),
      endian: _stringValue(json['endian']).toLowerCase(),
      n: _toInt(json['n']),
    );
  }

  /// 解壓並解碼成 double list（數值精度仍為 float32）。
  ///
  /// - 若 payload 格式不正確，會丟出 [FormatException]。
  List<double> decodeToDoubles() {
    if (n <= 0) {
      return const [];
    }
    if (endian.isNotEmpty && endian != 'little') {
      throw UnsupportedError('僅支援 little-endian float32（收到 endian=$endian）。');
    }
    if (f32ZlibB64.isEmpty) {
      throw const FormatException('f32_zlib_b64 為空，無法解碼。');
    }

    final compressed = base64Decode(f32ZlibB64);
    final raw = Uint8List.fromList(const ZLibDecoder().decodeBytes(compressed));
    final expectedBytes = n * 4;
    if (raw.lengthInBytes != expectedBytes) {
      throw FormatException(
        'float32 bytes 長度不符：期待 $expectedBytes bytes（n=$n），實際 ${raw.lengthInBytes} bytes。',
      );
    }

    final bd = ByteData.sublistView(raw);
    final out = List<double>.filled(n, 0.0, growable: false);
    for (var i = 0; i < n; i++) {
      out[i] = bd.getFloat32(i * 4, Endian.little).toDouble();
    }
    return out;
  }
}

/// 將 dynamic list 轉為 double list。
List<double> _toDoubleList(dynamic value) {
  if (value is List) {
    return value.map(_toDouble).toList();
  }
  return const [];
}

/// 將 dynamic 值安全轉為 double，缺值則回傳 0。
double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

/// 將 dynamic 值安全轉為 int，缺值則回傳 0。
int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

/// 解析後端的「float32+zlib+base64」或舊版的 double list 欄位。
///
/// - 新版：`{ f32_zlib_b64, endian, n }`
/// - 舊版：`[1.0, 2.0, ...]`
List<double> _toF32ZlibB64DecodedList(dynamic value) {
  if (value is Map<String, dynamic>) {
    return FloatArrayF32ZlibB64.fromJson(value).decodeToDoubles();
  }
  if (value is Map) {
    return FloatArrayF32ZlibB64.fromJson(Map<String, dynamic>.from(value))
        .decodeToDoubles();
  }
  return _toDoubleList(value);
}

/// 將 dynamic 轉成字串，避免 null 造成錯誤。
String _stringValue(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}
