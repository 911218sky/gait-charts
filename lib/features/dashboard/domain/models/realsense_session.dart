import 'package:flutter/foundation.dart';

/// 儲存單筆 Realsense session 的基本資訊。
@immutable
class RealsenseSessionItem {
  const RealsenseSessionItem({
    required this.sessionName,
    required this.npyPath,
    required this.bagPath,
    this.videoPath,
    this.createdAt,
    this.updatedAt,
  });

  final String sessionName;
  final String npyPath;
  final String bagPath;
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
/// 後端 `DELETE /realsense_pose_extractor/sessions/{session_name}` 會：
/// - 刪除 DB 紀錄
/// - 嘗試刪除對應的 npy 檔案
/// - bag 檔若仍被其他 session 共用，則只保留不刪
@immutable
class DeleteSessionResponse {
  const DeleteSessionResponse({
    required this.sessionName,
    required this.deletedDb,
    required this.deletedNpy,
    required this.deletedBag,
  });

  final String sessionName;
  final bool deletedDb;
  final bool deletedNpy;
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
      deletedBag: toBool(json['deleted_bag']),
    );
  }
}