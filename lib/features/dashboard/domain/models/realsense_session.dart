import 'package:flutter/foundation.dart';

/// 儲存單筆 Realsense session 的基本資訊。
@immutable
class RealsenseSessionItem {
  const RealsenseSessionItem({
    required this.sessionName,
    required this.npyPath,
    required this.bagPath,
    required this.bagFilename,
    this.videoPath,
    this.createdAt,
    this.updatedAt,
  });

  final String sessionName;
  final String npyPath;
  final String bagPath;
  /// BAG 檔案名稱（例如：1_1_607.bag）。
  final String bagFilename;
  /// 輸出的影片檔路徑（若有啟用 save_video）。
  final String? videoPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 是否有影片可播放。
  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;

  factory RealsenseSessionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final videoPath = json['video_path']?.toString();

    return RealsenseSessionItem(
      sessionName: json['session_name']?.toString() ?? '',
      npyPath: json['npy_path']?.toString() ?? '',
      bagPath: json['bag_path']?.toString() ?? '',
      bagFilename: json['bag_filename']?.toString() ?? '',
      videoPath: (videoPath != null && videoPath.isNotEmpty) ? videoPath : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

/// Realsense session 分頁結果封裝。
@immutable
class RealsenseSessionList {
  const RealsenseSessionList({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.items,
  });

  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<RealsenseSessionItem> items;

  bool get canLoadMore => page < totalPages;

  factory RealsenseSessionList.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return RealsenseSessionList(
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse('${json['total']}') ?? 0,
      page: json['page'] is int
          ? json['page'] as int
          : int.tryParse('${json['page']}') ?? 1,
      pageSize: json['page_size'] is int
          ? json['page_size'] as int
          : int.tryParse('${json['page_size']}') ?? 20,
      totalPages: json['total_pages'] is int
          ? json['total_pages'] as int
          : int.tryParse('${json['total_pages']}') ?? 0,
      items: itemsJson is List
          ? itemsJson
                .whereType<Map<String, dynamic>>()
                .map(RealsenseSessionItem.fromJson)
                .toList()
          : const [],
    );
  }
}

/// 刪除指定 session 的回應結果。
///
/// 後端 `POST /realsense-pose-extractor/sessions/delete` 會：
/// - 刪除 DB 紀錄
/// - 嘗試刪除對應的 npy 檔案
/// - bag 檔若仍被其他 session 共用，則只保留不刪
@immutable
class DeleteSessionResponse {
  const DeleteSessionResponse({
    required this.sessionName,
    required this.deletedDb,
    required this.deletedNpy,
    required this.deletedVideo,
    required this.deletedBag,
  });

  final String sessionName;
  final bool deletedDb;
  final bool deletedNpy;
  final bool deletedVideo;
  final bool deletedBag;

  factory DeleteSessionResponse.fromJson(Map<String, dynamic> json) {
    bool toBool(dynamic value) {
      if (value is bool) return value;
      final raw = value?.toString().toLowerCase().trim();
      return raw == 'true' || raw == '1' || raw == 'yes';
    }

    return DeleteSessionResponse(
      sessionName: json['session_name']?.toString() ?? '',
      deletedDb: toBool(json['deleted_db']),
      deletedNpy: toBool(json['deleted_npy']),
      deletedVideo: toBool(json['deleted_video']),
      deletedBag: toBool(json['deleted_bag']),
    );
  }
}

/// 批量刪除 sessions 的請求：POST /realsense-pose-extractor/sessions/delete
@immutable
class DeleteSessionsBatchRequest {
  const DeleteSessionsBatchRequest({required this.sessionNames});

  /// 要刪除的 session_name 列表（1-100）。
  final List<String> sessionNames;

  Map<String, Object?> toJson() {
    final normalized = sessionNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalized.isEmpty) {
      throw ArgumentError('sessionNames must not be empty');
    }
    if (normalized.length > 100) {
      throw ArgumentError('sessionNames length must be <= 100');
    }

    return <String, Object?>{'session_names': normalized};
  }
}

/// 批量刪除 sessions 的單筆明細。
@immutable
class DeleteSessionsBatchDetail {
  const DeleteSessionsBatchDetail({
    required this.sessionName,
    required this.deletedDb,
    required this.deletedNpy,
    required this.deletedVideo,
    required this.deletedBag,
  });

  final String sessionName;
  final bool deletedDb;
  final bool deletedNpy;
  final bool deletedVideo;
  final bool deletedBag;

  factory DeleteSessionsBatchDetail.fromJson(Map<String, dynamic> json) {
    bool toBool(dynamic value) {
      if (value is bool) return value;
      final raw = value?.toString().toLowerCase().trim();
      return raw == 'true' || raw == '1' || raw == 'yes';
    }

    return DeleteSessionsBatchDetail(
      sessionName: json['session_name']?.toString() ?? '',
      deletedDb: toBool(json['deleted_db']),
      deletedNpy: toBool(json['deleted_npy']),
      deletedVideo: toBool(json['deleted_video']),
      deletedBag: toBool(json['deleted_bag']),
    );
  }
}

/// 批量刪除 sessions 的回應：POST /realsense-pose-extractor/sessions/delete
@immutable
class DeleteSessionsBatchResponse {
  const DeleteSessionsBatchResponse({
    required this.totalRequested,
    required this.deletedSessions,
    required this.deletedDb,
    required this.deletedNpy,
    required this.deletedVideo,
    required this.deletedBag,
    required this.failed,
    required this.details,
  });

  final int totalRequested;
  final int deletedSessions;
  final int deletedDb;
  final int deletedNpy;
  final int deletedVideo;
  final int deletedBag;
  final List<String> failed;
  final List<DeleteSessionsBatchDetail> details;

  factory DeleteSessionsBatchResponse.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}'.trim()) ?? fallback;
    }

    final failedRaw = json['failed'];
    final detailsRaw = json['details'];

    return DeleteSessionsBatchResponse(
      totalRequested: toInt(json['total_requested']),
      deletedSessions: toInt(json['deleted_sessions']),
      deletedDb: toInt(json['deleted_db']),
      deletedNpy: toInt(json['deleted_npy']),
      deletedVideo: toInt(json['deleted_video']),
      deletedBag: toInt(json['deleted_bag']),
      failed: failedRaw is List
          ? failedRaw
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toList(growable: false)
          : const [],
      details: detailsRaw is List
          ? detailsRaw
                .whereType<Map<String, dynamic>>()
                .map(DeleteSessionsBatchDetail.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

/// Session 影片可用性檢查結果。
///
/// 用於快速判斷 session 是否有影片可播放，以及影片檔案是否存在。
@immutable
class VideoAvailability {
  const VideoAvailability({
    required this.sessionName,
    required this.hasVideo,
    required this.videoExists,
    this.videoPath,
  });

  final String sessionName;
  
  /// 是否有影片路徑（session 在擷取時有啟用 save_video）。
  final bool hasVideo;
  
  /// 影片檔案是否實際存在於磁碟上。
  final bool videoExists;
  
  /// 影片檔案路徑（若有）。
  final String? videoPath;

  /// 影片是否可播放（有路徑且檔案存在）。
  bool get isPlayable => hasVideo && videoExists;

  /// 取得影片狀態描述。
  String get statusMessage {
    if (!hasVideo) {
      return '此 Session 未生成影片';
    }
    if (!videoExists) {
      return '影片檔案遺失';
    }
    return '影片可播放';
  }

  factory VideoAvailability.fromJson(Map<String, dynamic> json) {
    bool toBool(dynamic value) {
      if (value is bool) return value;
      final raw = value?.toString().toLowerCase().trim();
      return raw == 'true' || raw == '1' || raw == 'yes';
    }

    final videoPath = json['video_path']?.toString();

    return VideoAvailability(
      sessionName: json['session_name']?.toString() ?? '',
      hasVideo: toBool(json['has_video']),
      videoExists: toBool(json['video_exists']),
      videoPath: (videoPath != null && videoPath.isNotEmpty) ? videoPath : null,
    );
  }
}