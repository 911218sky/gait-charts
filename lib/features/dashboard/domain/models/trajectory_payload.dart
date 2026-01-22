part of 'dashboard_overview.dart';

/// trajectory_payload API 的查詢設定。
class TrajectoryPayloadConfig {
  const TrajectoryPayloadConfig({
    this.projection = 'xz',
    this.smoothWindow = 3,
    this.minVAbs = 15,
    this.flatFrac = 0.7,
    this.leftJoint = 'L_HIP',
    this.rightJoint = 'R_HIP',
    this.fpsOut = 24,
    this.speed = 1.0,
    this.frameJump = 3,
    this.rotate180 = true,
    this.padScale = 0.08,
  });

  final String projection;
  final int smoothWindow;
  final double minVAbs;
  final double flatFrac;

  /// 關節 spec：支援 int / String（與後端 Union[int,str] 對齊）。
  final Object leftJoint;
  final Object rightJoint;

  /// 建議前端播放 fps（後端也會用來決定 downsample stride）。
  final int fpsOut;

  /// 播放速度倍率（會影響後端下採樣 stride）。
  final double speed;

  /// 額外每 N 幀取 1 幀（再一次下採樣）。
  final int frameJump;

  /// 是否以 bounds 中心旋轉 180°（後端若已旋轉，前端不需再處理）。
  final bool rotate180;

  /// bounds padding 比例（乘上 span）。
  final double padScale;

  TrajectoryPayloadConfig copyWith({
    String? projection,
    int? smoothWindow,
    double? minVAbs,
    double? flatFrac,
    Object? leftJoint,
    Object? rightJoint,
    int? fpsOut,
    double? speed,
    int? frameJump,
    bool? rotate180,
    double? padScale,
  }) {
    return TrajectoryPayloadConfig(
      projection: projection ?? this.projection,
      smoothWindow: smoothWindow ?? this.smoothWindow,
      minVAbs: minVAbs ?? this.minVAbs,
      flatFrac: flatFrac ?? this.flatFrac,
      leftJoint: leftJoint ?? this.leftJoint,
      rightJoint: rightJoint ?? this.rightJoint,
      fpsOut: fpsOut ?? this.fpsOut,
      speed: speed ?? this.speed,
      frameJump: frameJump ?? this.frameJump,
      rotate180: rotate180 ?? this.rotate180,
      padScale: padScale ?? this.padScale,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'projection': projection,
    'smooth_window_s': smoothWindow,
    'min_v_abs': minVAbs,
    'flat_frac': flatFrac,
    'left_joint': leftJoint,
    'right_joint': rightJoint,
    'fps_out': fpsOut,
    'speed': speed,
    'frame_jump': frameJump,
    'rotate_180': rotate180,
    'pad_scale': padScale,
  };
}

// ===========================================================================
// Response models
// ===========================================================================

/// API 回傳的完整軌跡資料結構，包含元數據、場景資訊、壓縮幀數據與分圈資訊。
class TrajectoryPayloadResponse {
  const TrajectoryPayloadResponse({
    required this.meta,
    required this.scene,
    required this.frames,
    required this.laps,
    required this.widthStats,
  });

  final TrajectoryMeta meta;
  final TrajectoryScene scene;
  final TrajectoryFrames frames;
  final List<TrajectoryLap> laps;

  /// 軌跡寬度統計（最寬/最窄圈、變異度）；無有效數據時為 null。
  final TrajectoryWidthStats? widthStats;

  factory TrajectoryPayloadResponse.fromJson(Map<String, dynamic> json) {
    final lapsJson = json['laps'];
    final widthStatsJson = json['width_stats'];
    return TrajectoryPayloadResponse(
      meta: TrajectoryMeta.fromJson(
        (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      scene: TrajectoryScene.fromJson(
        (json['scene'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      frames: TrajectoryFrames.fromJson(
        (json['frames'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      // Dio/JSON decode 在不同平台下，list element 可能是 Map<dynamic,dynamic>；
      // 這裡統一 cast 後再解析，避免 markers 被不小心吃掉。
      laps: lapsJson is List
          ? lapsJson
                .whereType<Map<dynamic, dynamic>>()
                .map((m) => TrajectoryLap.fromJson(m.cast<String, dynamic>()))
                .toList()
          : const [],
      widthStats: widthStatsJson is Map
          ? TrajectoryWidthStats.fromJson(widthStatsJson.cast<String, dynamic>())
          : null,
    );
  }
}

/// 軌跡寬度統計資料。
class TrajectoryWidthStats {
  const TrajectoryWidthStats({
    required this.widestLapIndex,
    required this.widestLapWidthM,
    required this.narrowestLapIndex,
    required this.narrowestLapWidthM,
    required this.meanWidthM,
    required this.stdWidthM,
    required this.cvPct,
  });

  /// 最寬圈的圈次（1-based）；無有效數據時為 null。
  final int? widestLapIndex;

  /// 最寬圈的軌跡寬度（公尺）。
  final double? widestLapWidthM;

  /// 最窄圈的圈次（1-based）；無有效數據時為 null。
  final int? narrowestLapIndex;

  /// 最窄圈的軌跡寬度（公尺）。
  final double? narrowestLapWidthM;

  /// 所有圈的平均軌跡寬度（公尺）。
  final double? meanWidthM;

  /// 軌跡寬度標準差（公尺）。
  final double? stdWidthM;

  /// 軌跡寬度變異係數 (%)，即 std/mean * 100。
  final double? cvPct;

  factory TrajectoryWidthStats.fromJson(Map<String, dynamic> json) {
    return TrajectoryWidthStats(
      widestLapIndex: _toNullableInt(json['widest_lap_index']),
      widestLapWidthM: _toNullableDouble(json['widest_lap_width_m']),
      narrowestLapIndex: _toNullableInt(json['narrowest_lap_index']),
      narrowestLapWidthM: _toNullableDouble(json['narrowest_lap_width_m']),
      meanWidthM: _toNullableDouble(json['mean_width_m']),
      stdWidthM: _toNullableDouble(json['std_width_m']),
      cvPct: _toNullableDouble(json['cv_pct']),
    );
  }
}

/// 軌跡數據的元數據，包含投影面、FPS、邊界範圍 (Bounds) 與編碼格式等資訊。
class TrajectoryMeta {
  const TrajectoryMeta({
    required this.projection,
    required this.fpsOut,
    required this.rotate180,
    required this.bounds,
    required this.encoding,
    required this.endian,
    required this.nFrames,
  });

  final String projection;
  final int fpsOut;
  final bool rotate180;
  final TrajectoryBounds bounds;
  final String encoding;
  final String endian;
  final int nFrames;

  factory TrajectoryMeta.fromJson(Map<String, dynamic> json) {
    return TrajectoryMeta(
      projection: _stringValue(json['projection']),
      fpsOut: _toInt(json['fps_out']),
      rotate180: json['rotate_180'] == true,
      bounds: TrajectoryBounds.fromJson(
        (json['bounds'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      encoding: _stringValue(json['encoding']),
      endian: _stringValue(json['endian']),
      nFrames: _toInt(json['n_frames']),
    );
  }
}

/// 軌跡數據的邊界範圍 (Min/Max)，用於反量化 (De-quantization) 座標。
class TrajectoryBounds {
  const TrajectoryBounds({
    required this.xmin,
    required this.xmax,
    required this.ymin,
    required this.ymax,
  });

  final double xmin;
  final double xmax;
  final double ymin;
  final double ymax;

  double get dx => (xmax - xmin).abs() < 1e-12 ? 1e-12 : (xmax - xmin);
  double get dy => (ymax - ymin).abs() < 1e-12 ? 1e-12 : (ymax - ymin);

  factory TrajectoryBounds.fromJson(Map<String, dynamic> json) {
    return TrajectoryBounds(
      xmin: _toDouble(json['xmin']),
      xmax: _toDouble(json['xmax']),
      ymin: _toDouble(json['ymin']),
      ymax: _toDouble(json['ymax']),
    );
  }
}

/// 場景物件 (如椅子、三角錐) 的原始數據，包含反量化前的 u16 座標與半徑。
class TrajectoryScene {
  const TrajectoryScene({
    required this.chairXyU16,
    required this.coneXyU16,
    required this.rChair,
    required this.rCone,
  });

  final List<int> chairXyU16;
  final List<int> coneXyU16;
  final double rChair;
  final double rCone;

  factory TrajectoryScene.fromJson(Map<String, dynamic> json) {
    final chair = json['chair_xy_u16'];
    final cone = json['cone_xy_u16'];
    return TrajectoryScene(
      chairXyU16: chair is List ? chair.map(_toInt).toList() : const [0, 0],
      coneXyU16: cone is List ? cone.map(_toInt).toList() : const [0, 0],
      rChair: _toDouble(json['r_chair']),
      rCone: _toDouble(json['r_cone']),
    );
  }
}

/// 包含壓縮後的軌跡幀數據 (Base64 + Zlib)，解壓後為左右腳的座標序列。
class TrajectoryFrames {
  const TrajectoryFrames({required this.xyLrU16ZlibB64});

  final String xyLrU16ZlibB64;

  factory TrajectoryFrames.fromJson(Map<String, dynamic> json) {
    return TrajectoryFrames(
      xyLrU16ZlibB64: _stringValue(json['xy_lr_u16_zlib_b64']),
    );
  }
}

/// 單圈軌跡的資訊，包含該圈在 Payload 中的起始/結束索引與標記點。
class TrajectoryLap {
  const TrajectoryLap({
    required this.lapIndex,
    required this.lapDirection,
    required this.payloadStartK,
    required this.payloadEndK,
    required this.markers,
    required this.trajectoryWidthM,
  });

  final int lapIndex;

  /// 圈數方向：clockwise（順時針）、counterclockwise（逆時針）或 unknown（未知）。
  final String lapDirection;
  final int? payloadStartK;
  final int? payloadEndK;
  final TrajectoryLapMarkers markers;

  /// 此圈軌跡寬度（公尺），即軌跡垂直於行進方向的最大偏移範圍。
  final double? trajectoryWidthM;

  factory TrajectoryLap.fromJson(Map<String, dynamic> json) {
    return TrajectoryLap(
      lapIndex: _toInt(json['lap_index']),
      lapDirection: _stringValue(json['lap_direction'], fallback: 'unknown'),
      payloadStartK: _toNullableInt(json['payload_start_k']),
      payloadEndK: _toNullableInt(json['payload_end_k']),
      markers: TrajectoryLapMarkers.fromJson(
        (json['markers'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      trajectoryWidthM: _toNullableDouble(json['trajectory_width_m']),
    );
  }
}

/// 單圈內的關鍵標記點索引 (如椅子起點/終點、三角錐起點/終點)。
class TrajectoryLapMarkers {
  const TrajectoryLapMarkers({
    required this.coneStartK,
    required this.coneEndK,
    required this.chairStartK,
    required this.chairEndK,
  });

  final int? coneStartK;
  final int? coneEndK;
  final int? chairStartK;
  final int? chairEndK;

  factory TrajectoryLapMarkers.fromJson(Map<String, dynamic> json) {
    return TrajectoryLapMarkers(
      coneStartK: _toNullableInt(json['cone_start_k']),
      coneEndK: _toNullableInt(json['cone_end_k']),
      chairStartK: _toNullableInt(json['chair_start_k']),
      chairEndK: _toNullableInt(json['chair_end_k']),
    );
  }
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

// ===========================================================================
// Decoding / de-quantization (domain, web-safe)
// ===========================================================================

/// 解壓並反量化後的 payload，可直接用於繪圖（仍保持純 Dart 型別，避免 UI 依賴）。
class TrajectoryDecodedPayload {
  const TrajectoryDecodedPayload({
    required this.meta,
    required this.sceneWorld,
    required this.leftXy,
    required this.rightXy,
    required this.centerXy,
    required this.laps,
    required this.widthStats,
  });

  final TrajectoryMeta meta;
  final TrajectorySceneWorld sceneWorld;

  /// (x,y) world 座標：length = nFrames * 2。
  final Float32List leftXy;
  final Float32List rightXy;
  final Float32List centerXy;

  final List<TrajectoryLap> laps;

  /// 軌跡寬度統計（最寬/最窄圈、變異度）；無有效數據時為 null。
  final TrajectoryWidthStats? widthStats;

  int get nFrames => meta.nFrames;

  static final empty = TrajectoryDecodedPayload(
    meta: const TrajectoryMeta(
      projection: '',
      fpsOut: 0,
      rotate180: false,
      bounds: TrajectoryBounds(xmin: 0, xmax: 0, ymin: 0, ymax: 0),
      encoding: '',
      endian: 'little',
      nFrames: 0,
    ),
    sceneWorld: const TrajectorySceneWorld(
      chair: Point(0, 0),
      cone: Point(0, 0),
      rChair: 0,
      rCone: 0,
    ),
    leftXy: Float32List(0),
    rightXy: Float32List(0),
    centerXy: Float32List(0),
    laps: const [],
    widthStats: null,
  );
}

/// 反量化後的世界座標場景物件，包含椅子與三角錐的實際座標 (`Point<double>`)。
class TrajectorySceneWorld {
  const TrajectorySceneWorld({
    required this.chair,
    required this.cone,
    required this.rChair,
    required this.rCone,
  });

  final Point<double> chair;
  final Point<double> cone;
  final double rChair;
  final double rCone;
}

/// 依據 meta.bounds 將 uint16 反量化回世界座標，並解出每幀左右關節點位。
///
/// - 解壓使用 `archive`，可在 Flutter Web 運作（不依賴 dart:io）
/// - 解壓後的 bytes layout：
///   - little-endian uint16 array
///   - length = meta.nFrames * 4
///   - 每幀排列：[xL, yL, xR, yR]
TrajectoryDecodedPayload decodeTrajectoryPayload(TrajectoryPayloadResponse response) {
  final meta = response.meta;
  final nFrames = meta.nFrames;
  if (nFrames <= 0) {
    return TrajectoryDecodedPayload.empty;
  }

  if (meta.endian.isNotEmpty && meta.endian != 'little') {
    // 目前後端固定 little；若未來有變更，先 fail-fast 避免錯誤解碼。
    throw const FormatException('trajectory payload endian 目前僅支援 little');
  }

  // frames 透過 base64 包裝 zlib 壓縮後的 u16 座標，先做 base64 decode。
  final b64 = response.frames.xyLrU16ZlibB64;
  if (b64.isEmpty) {
    throw const FormatException('trajectory payload frames 為空');
  }

  final compressed = base64Decode(b64);
  final raw = const ZLibDecoder().decodeBytes(compressed);
  final rawBytes = Uint8List.fromList(raw);

  // 每幀 4 個 u16（xL, yL, xR, yR），共 8 bytes。
  final expectedBytes = nFrames * 4 * 2;
  if (rawBytes.lengthInBytes != expectedBytes) {
    throw FormatException(
      'trajectory payload frames 長度不符：expected=$expectedBytes bytes, got=${rawBytes.lengthInBytes}',
    );
  }

  // 將 rawBytes 轉為 ByteData 以方便存取。
  final bytes = ByteData.sublistView(rawBytes);
  final bounds = meta.bounds;
  final dx = bounds.dx;
  final dy = bounds.dy;

  double deqX(int u) => bounds.xmin + (u / 65535.0) * dx;
  double deqY(int u) => bounds.ymin + (u / 65535.0) * dy;

  final leftXy = Float32List(nFrames * 2);
  final rightXy = Float32List(nFrames * 2);
  final centerXy = Float32List(nFrames * 2);

  for (var k = 0; k < nFrames; k++) {
    // 每幀的 byte offset，u16 皆為 little-endian。
    final base = k * 8; // 4 u16 * 2 bytes
    final xL = bytes.getUint16(base + 0, Endian.little);
    final yL = bytes.getUint16(base + 2, Endian.little);
    final xR = bytes.getUint16(base + 4, Endian.little);
    final yR = bytes.getUint16(base + 6, Endian.little);

    // 反量化回世界座標（以 bounds 做線性映射）。
    // 將 int u16 轉為 double。
    final lX = deqX(xL);
    final lY = deqY(yL);
    final rX = deqX(xR);
    final rY = deqY(yR);

    // 左右關節與中心點分別存成 Float32List，長度 = nFrames * 2 (x,y)。
    final i = k * 2;
    leftXy[i] = lX.toDouble();
    leftXy[i + 1] = lY.toDouble();
    rightXy[i] = rX.toDouble();
    rightXy[i + 1] = rY.toDouble();
    centerXy[i] = ((lX + rX) * 0.5).toDouble();
    centerXy[i + 1] = ((lY + rY) * 0.5).toDouble();
  }

  // 將 u16 反量化回世界座標。
  Point<double> deqU16Point(List<int> xy) {
    final ux = xy.isNotEmpty ? xy.first : 0;
    final uy = xy.length > 1 ? xy[1] : 0;
    return Point<double>(deqX(ux), deqY(uy));
  }

  // 場景中椅子/錐的座標也以 u16 存儲，需同樣反量化以確保與軌跡座標系一致。
  final sceneWorld = TrajectorySceneWorld(
    chair: deqU16Point(response.scene.chairXyU16),
    cone: deqU16Point(response.scene.coneXyU16),
    rChair: response.scene.rChair,
    rCone: response.scene.rCone,
  );

  return TrajectoryDecodedPayload(
    meta: meta,
    sceneWorld: sceneWorld,
    leftXy: leftXy,
    rightXy: rightXy,
    centerXy: centerXy,
    laps: response.laps,
    widthStats: response.widthStats,
  );
}


