import 'package:flutter/foundation.dart';

/// 伺服器上的單筆 .bag 檔案資訊。
@immutable
class BagFileItem {
  const BagFileItem({
    required this.bagId,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  /// API 識別用（通常是相對路徑，如 `subdir/1.bag`）。
  final String bagId;

  /// 檔名（不含路徑）。
  final String name;

  /// 檔案大小（bytes）。
  final int sizeBytes;

  /// 最後修改時間（若後端回傳格式異常，會 fallback 為 Unix epoch）。
  final DateTime modifiedAt;

  factory BagFileItem.fromJson(Map<String, dynamic> json) {
    final bagId = (json['bag_id'] ?? '').toString().trim();
    final name = (json['name'] ?? '').toString().trim();
    final size = json['size_bytes'];
    final sizeBytes = switch (size) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };
    final modifiedRaw = json['modified_at'];
    final modifiedAt = _parseDateTime(modifiedRaw);

    return BagFileItem(
      bagId: bagId,
      name: name.isNotEmpty ? name : _fallbackNameFromId(bagId),
      sizeBytes: sizeBytes < 0 ? 0 : sizeBytes,
      modifiedAt: modifiedAt,
    );
  }

  static String _fallbackNameFromId(String bagId) {
    final normalized = bagId.trim();
    if (normalized.isEmpty) return '';
    final parts = normalized.split(RegExp(r'[/\\]'));
    return parts.isEmpty ? normalized : parts.last;
  }
}

/// 伺服器 bag 清單分頁回應。
@immutable
class BagFileListResponse {
  const BagFileListResponse({
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
  final List<BagFileItem> items;

  factory BagFileListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <BagFileItem>[];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          items.add(BagFileItem.fromJson(it));
        } else if (it is Map) {
          items.add(BagFileItem.fromJson(Map<String, dynamic>.from(it)));
        }
      }
    }

    int toInt(dynamic v) {
      return switch (v) {
        int x => x,
        num x => x.toInt(),
        String x => int.tryParse(x) ?? 0,
        _ => 0,
      };
    }

    return BagFileListResponse(
      total: toInt(json['total']),
      page: toInt(json['page']),
      pageSize: toInt(json['page_size']),
      totalPages: toInt(json['total_pages']),
      items: items,
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;
  }
  if (value is num) {
    // 兼容 epoch seconds
    final ms = (value.toDouble() * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}


