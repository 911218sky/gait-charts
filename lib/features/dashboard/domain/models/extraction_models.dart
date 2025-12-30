part of 'dashboard_overview.dart';

/// 控制姿態萃取流程的參數設定。
class ExtractConfig {
  const ExtractConfig({
    this.force = false,
    this.skipFrames = 4,
    this.maxFrames = 10800,
    this.modelComplexity = 1,
    this.minDetectionConfidence = 0.5,
    this.minTrackingConfidence = 0.5,
    this.maxConcurrency = 3,
    this.calibratePose = true,
    this.saveVideo = true,
  });

  final bool force; // 是否強制重新萃取
  final int skipFrames; // 跳過幀數
  final int maxFrames; // 最大幀數
  final int modelComplexity; // 模型複雜度
  final double minDetectionConfidence; // 最小偵測信心度
  final double minTrackingConfidence; // 最小追蹤信心度
  final int maxConcurrency; // 最大並行處理數量
  final bool calibratePose; // 是否在寫入前校準姿勢
  final bool saveVideo; // 是否輸出帶有骨架標註的影片

  ExtractConfig copyWith({
    bool? force,
    int? skipFrames,
    int? maxFrames,
    int? modelComplexity,
    double? minDetectionConfidence,
    double? minTrackingConfidence,
    int? maxConcurrency,
    bool? calibratePose,
    bool? saveVideo,
  }) {
    return ExtractConfig(
      force: force ?? this.force,
      skipFrames: skipFrames ?? this.skipFrames,
      maxFrames: maxFrames ?? this.maxFrames,
      modelComplexity: modelComplexity ?? this.modelComplexity,
      minDetectionConfidence:
          minDetectionConfidence ?? this.minDetectionConfidence,
      minTrackingConfidence:
          minTrackingConfidence ?? this.minTrackingConfidence,
      maxConcurrency: maxConcurrency ?? this.maxConcurrency,
      calibratePose: calibratePose ?? this.calibratePose,
      saveVideo: saveVideo ?? this.saveVideo,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'force': force,
    'skip_frames': skipFrames,
    'max_frames': maxFrames,
    'model_complexity': modelComplexity,
    'min_detection_confidence': minDetectionConfidence,
    'min_tracking_confidence': minTrackingConfidence,
    'calibrate_pose': calibratePose,
    'save_video': saveVideo,
  };
}

/// 代表一次萃取作業的結果資料。
class ExtractResult {
  const ExtractResult({
    required this.sessionName,
    required this.bagPath,
    required this.npyPath,
    required this.success,
    this.bagHash,
  });

  final String sessionName; // 工作階段名稱
  final String bagPath; // Bag 檔案路徑
  final String npyPath; // NPY 檔案路徑
  final String? bagHash; // bag hash（後端若未提供則為 null）
  final bool success; // 是否成功

  factory ExtractResult.fromJson(Map<String, dynamic> json) {
    return ExtractResult(
      sessionName: _stringValue(json['session_name']),
      bagPath: _stringValue(json['bag_path']),
      npyPath: _stringValue(json['npy_path']),
      bagHash: _stringValue(json['bag_hash']).trim().isEmpty
          ? null
          : _stringValue(json['bag_hash']),
      success: json['success'] == true,
    );
  }
}

/// POST /extract（background=true）建立的 job 回應。
class ExtractJobCreatedResponse {
  const ExtractJobCreatedResponse({
    required this.jobId,
    required this.status,
    required this.statusUrl,
    required this.createdAt,
  });

  final String jobId;
  final String status; // pending/running/succeeded/failed
  final String statusUrl;
  final DateTime createdAt;

  factory ExtractJobCreatedResponse.fromJson(Map<String, dynamic> json) {
    final createdRaw = _stringValue(json['created_at']);
    final createdAt = DateTime.tryParse(createdRaw) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ExtractJobCreatedResponse(
      jobId: _stringValue(json['job_id']),
      status: _stringValue(json['status']),
      statusUrl: _stringValue(json['status_url']),
      createdAt: createdAt,
    );
  }
}

/// GET /extract/jobs/{job_id} 的狀態回應。
class ExtractJobStatusResponse {
  const ExtractJobStatusResponse({
    required this.jobId,
    required this.status,
    this.error,
    this.result,
  });

  final String jobId;
  final String status; // pending/running/succeeded/failed
  final String? error;
  final ExtractResult? result;

  factory ExtractJobStatusResponse.fromJson(Map<String, dynamic> json) {
    final resultRaw = json['result'];
    ExtractResult? parsedResult;
    if (resultRaw is Map<String, dynamic>) {
      parsedResult = ExtractResult.fromJson(resultRaw);
    } else if (resultRaw is Map) {
      parsedResult = ExtractResult.fromJson(Map<String, dynamic>.from(resultRaw));
    }

    final err = _stringValue(json['error']).trim();
    return ExtractJobStatusResponse(
      jobId: _stringValue(json['job_id']),
      status: _stringValue(json['status']),
      error: err.isEmpty ? null : err,
      result: parsedResult,
    );
  }
}
