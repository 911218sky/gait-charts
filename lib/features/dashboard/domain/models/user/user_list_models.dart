import 'package:flutter/foundation.dart';
import 'package:gait_charts/features/dashboard/domain/utils/json_parsing_utils.dart';

/// 使用者列表單筆資料
@immutable
class UserListItem {
  const UserListItem({
    required this.userCode,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.cohort = const ['正常人'],
  });

  final String userCode;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> cohort;

  factory UserListItem.fromJson(Map<String, Object?> json) {
    return UserListItem(
      userCode: stringValue(json['user_code']) ?? '',
      name: stringValue(json['name']) ?? '',
      createdAt:
          parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseDateTime(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      cohort: normalizeCohortList(stringListValue(json['cohort'])),
    );
  }
}

/// 使用者列表回傳（分頁）。
@immutable
class UserListResponse {
  const UserListResponse({
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
  final List<UserListItem> items;

  bool get canLoadMore => page < totalPages;

  factory UserListResponse.fromJson(Map<String, Object?> json) {
    final itemsRaw = json['items'];
    return UserListResponse(
      total: intValue(json['total']) ?? 0,
      page: intValue(json['page']) ?? 1,
      pageSize: intValue(json['page_size']) ?? 20,
      totalPages: intValue(json['total_pages']) ?? 0,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map<String, Object?>>()
                .map(UserListItem.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

/// 使用者名稱搜尋（前綴）回傳項目。
///
/// 用於 `/users/search`：只回傳可用來「顯示清單 + 選擇 user_code」的最小資訊。
@immutable
class UserSearchSuggestionItem {
  const UserSearchSuggestionItem({
    required this.userCode,
    required this.name,
    required this.createdAt,
    this.cohort = const ['正常人'],
  });

  final String userCode;
  final String name;
  final DateTime createdAt;
  final List<String> cohort;

  factory UserSearchSuggestionItem.fromJson(Map<String, Object?> json) {
    return UserSearchSuggestionItem(
      userCode: stringValue(json['user_code']) ?? '',
      name: stringValue(json['name']) ?? '',
      createdAt:
          parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      cohort: normalizeCohortList(stringListValue(json['cohort'])),
    );
  }
}

/// 使用者名稱搜尋（前綴）回傳。
@immutable
class UserSearchSuggestionResponse {
  const UserSearchSuggestionResponse({
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
  final List<UserSearchSuggestionItem> items;

  bool get canLoadMore => page < totalPages;

  factory UserSearchSuggestionResponse.fromJson(Map<String, Object?> json) {
    final itemsRaw = json['items'];
    return UserSearchSuggestionResponse(
      total: intValue(json['total']) ?? 0,
      page: intValue(json['page']) ?? 1,
      pageSize: intValue(json['page_size']) ?? 20,
      totalPages: intValue(json['total_pages']) ?? 0,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map<String, Object?>>()
                .map(UserSearchSuggestionItem.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}
