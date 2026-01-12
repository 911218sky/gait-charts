import 'package:flutter/foundation.dart';
import 'package:gait_charts/features/dashboard/domain/utils/json_parsing_utils.dart';

/// 刪除使用者（批量）請求：POST /users/delete
@immutable
class DeleteUsersBatchRequest {
  const DeleteUsersBatchRequest({
    required this.userCodes,
    this.deleteSessions = false,
  });

  /// 要刪除的 user_codes（1-100）。
  final List<String> userCodes;

  /// true：連同刪除該使用者名下 sessions（DB 紀錄）
  /// false：只解除綁定（保留 sessions）
  final bool deleteSessions;

  Map<String, Object?> toJson() {
    final codes = userCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (codes.isEmpty) {
      throw ArgumentError('userCodes must not be empty');
    }
    if (codes.length > 100) {
      throw ArgumentError('userCodes length must be <= 100');
    }

    return <String, Object?>{
      'user_codes': codes,
      'delete_sessions': deleteSessions,
    };
  }
}

/// 刪除使用者（批量）回應明細。
@immutable
class DeleteUsersBatchDetail {
  const DeleteUsersBatchDetail({
    required this.userCode,
    required this.deletedUser,
    required this.unlinkedSessions,
    required this.deletedSessions,
  });

  final String userCode;
  final bool deletedUser;
  final int unlinkedSessions;
  final int deletedSessions;

  factory DeleteUsersBatchDetail.fromJson(Map<String, Object?> json) {
    return DeleteUsersBatchDetail(
      userCode: stringValue(json['user_code']) ?? '',
      deletedUser: boolValue(json['deleted_user']) ?? false,
      unlinkedSessions: intValue(json['unlinked_sessions']) ?? 0,
      deletedSessions: intValue(json['deleted_sessions']) ?? 0,
    );
  }
}

/// 刪除使用者（批量）回應：POST /users/delete
@immutable
class DeleteUsersBatchResponse {
  const DeleteUsersBatchResponse({
    required this.totalRequested,
    required this.deletedUsers,
    required this.totalUnlinkedSessions,
    required this.totalDeletedSessions,
    required this.failed,
    required this.details,
  });

  final int totalRequested;
  final int deletedUsers;
  final int totalUnlinkedSessions;
  final int totalDeletedSessions;
  final List<String> failed;
  final List<DeleteUsersBatchDetail> details;

  factory DeleteUsersBatchResponse.fromJson(Map<String, Object?> json) {
    final failedRaw = json['failed'];
    final detailsRaw = json['details'];
    return DeleteUsersBatchResponse(
      totalRequested: intValue(json['total_requested']) ?? 0,
      deletedUsers: intValue(json['deleted_users']) ?? 0,
      totalUnlinkedSessions: intValue(json['total_unlinked_sessions']) ?? 0,
      totalDeletedSessions: intValue(json['total_deleted_sessions']) ?? 0,
      failed: failedRaw is List
          ? failedRaw
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toList(growable: false)
          : const [],
      details: detailsRaw is List
          ? detailsRaw
                .whereType<Map<String, Object?>>()
                .map(DeleteUsersBatchDetail.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

/// 刪除使用者回應明細（由批量刪除回應的 details 取出）。
@immutable
class DeleteUserResponse {
  const DeleteUserResponse({
    required this.userCode,
    required this.deletedUser,
    required this.unlinkedSessions,
    required this.deletedSessions,
  });

  final String userCode;
  final bool deletedUser;
  final int unlinkedSessions;
  final int deletedSessions;

  factory DeleteUserResponse.fromJson(Map<String, Object?> json) {
    return DeleteUserResponse(
      userCode: stringValue(json['user_code']) ?? '',
      deletedUser: boolValue(json['deleted_user']) ?? false,
      unlinkedSessions: intValue(json['unlinked_sessions']) ?? 0,
      deletedSessions: intValue(json['deleted_sessions']) ?? 0,
    );
  }
}
