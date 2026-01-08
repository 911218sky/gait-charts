import 'package:flutter/foundation.dart';
import 'package:gait_charts/features/dashboard/domain/utils/json_parsing_utils.dart';
import 'user_item.dart';

/// 族群統計項目（GET /v1/users/cohorts）。
@immutable
class UserCohortStat {
  const UserCohortStat({required this.cohort, required this.userCount});

  final String cohort;
  final int userCount;

  factory UserCohortStat.fromJson(Map<String, Object?> json) {
    return UserCohortStat(
      cohort: stringValue(json['cohort']) ?? '',
      userCount: intValue(json['user_count']) ?? 0,
    );
  }
}

/// 族群統計回傳：GET /v1/users/cohorts
@immutable
class UserCohortsResponse {
  const UserCohortsResponse({required this.cohorts, required this.totalCohorts});

  final List<UserCohortStat> cohorts;
  final int totalCohorts;

  factory UserCohortsResponse.fromJson(Map<String, Object?> json) {
    final cohortsRaw = json['cohorts'];
    return UserCohortsResponse(
      cohorts: cohortsRaw is List
          ? cohortsRaw
                .whereType<Map<String, Object?>>()
                .map(UserCohortStat.fromJson)
                .where((e) => e.cohort.trim().isNotEmpty)
                .toList(growable: false)
          : const [],
      totalCohorts: intValue(json['total_cohorts']) ?? 0,
    );
  }
}


/// 透過 BAG 檔案名稱尋找使用者的請求：POST /v1/users/find-by-bag
@immutable
class FindUserByBagRequest {
  const FindUserByBagRequest({required this.bagFilename});

  /// BAG 檔案名稱（例如：1_1_607.bag）
  final String bagFilename;

  Map<String, Object?> toJson() {
    return <String, Object?>{'bag_filename': bagFilename.trim()};
  }
}

/// 透過 BAG 檔案尋找使用者的回傳：POST /v1/users/find-by-bag
@immutable
class FindUserByBagResponse {
  const FindUserByBagResponse({
    required this.found,
    required this.sessions,
    required this.totalSessions,
    this.user,
  });

  /// 是否找到綁定的使用者
  final bool found;

  /// 找到的使用者資料（若有）
  final UserItem? user;

  /// 該使用者的所有 session 列表（found=True 時）
  /// 或使用該 bag_filename 的 session 列表（found=False 時）
  final List<UserSessionItem> sessions;

  /// 該使用者的 session 總數（found=True 時）
  /// 或使用該 bag_filename 的 session 總數（found=False 時）
  final int totalSessions;

  factory FindUserByBagResponse.fromJson(Map<String, Object?> json) {
    final userRaw = json['user'];
    final sessionsRaw = json['sessions'];
    return FindUserByBagResponse(
      found: boolValue(json['found']) ?? false,
      user: userRaw is Map
          ? UserItem.fromJson(userRaw.cast<String, Object?>())
          : null,
      sessions: sessionsRaw is List
          ? sessionsRaw
                .whereType<Map<String, Object?>>()
                .map(UserSessionItem.fromJson)
                .toList(growable: false)
          : const [],
      totalSessions: intValue(json['total_sessions']) ?? 0,
    );
  }
}
