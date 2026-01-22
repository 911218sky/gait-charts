import 'package:flutter/foundation.dart';
import 'package:gait_charts/features/dashboard/domain/utils/json_parsing_utils.dart';

/// 把 session(bag) 綁到使用者：POST /v1/users/{user_code}/sessions/link
@immutable
class LinkUserSessionRequest {
  const LinkUserSessionRequest({this.sessionName, this.bagFilename});

  final String? sessionName;
  final String? bagFilename;

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};
    final normalizedSessionName = _stringOrNull(sessionName);
    final normalizedBagFilename = _stringOrNull(bagFilename);

    if (normalizedSessionName != null) {
      payload['session_name'] = normalizedSessionName;
    }
    if (normalizedBagFilename != null) {
      payload['bag_filename'] = normalizedBagFilename;
    }

    if (payload.isEmpty) {
      throw ArgumentError('Either sessionName or bagFilename is required');
    }

    return payload;
  }
}

/// 把 session(bag) 從使用者解除綁定：POST /v1/users/{user_code}/sessions/unlink
@immutable
class UnlinkUserSessionRequest {
  const UnlinkUserSessionRequest({
    this.unlinkAll = false,
    this.sessionNames,
    this.bagFilenames,
  });

  final bool unlinkAll;
  /// 要解除綁定的 session_names（1-100）。
  final List<String>? sessionNames;
  /// 要解除綁定的 bag_filenames（1-100，推薦使用）。
  final List<String>? bagFilenames;

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};

    List<String>? normalizeList(List<String>? raw) {
      if (raw == null) return null;
      final out = raw
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList(growable: false);
      return out.isEmpty ? null : out;
    }

    final normalizedSessionNames = normalizeList(sessionNames);
    final normalizedBagFilenames = normalizeList(bagFilenames);

    if (unlinkAll) {
      if (normalizedSessionNames != null || normalizedBagFilenames != null) {
        throw ArgumentError(
          'unlinkAll cannot be used together with sessionNames/bagFilenames',
        );
      }
      payload['unlink_all'] = true;
      return payload;
    }

    if (normalizedSessionNames != null) {
      if (normalizedSessionNames.length > 100) {
        throw ArgumentError('sessionNames length must be <= 100');
      }
      payload['session_names'] = normalizedSessionNames;
    }
    if (normalizedBagFilenames != null) {
      if (normalizedBagFilenames.length > 100) {
        throw ArgumentError('bagFilenames length must be <= 100');
      }
      payload['bag_filenames'] = normalizedBagFilenames;
    }

    if (payload.isEmpty) {
      throw ArgumentError(
        'Either sessionNames or bagFilenames is required (or set unlinkAll=true)',
      );
    }

    // 明確帶 false（後端 schema 預設 false；帶著更直觀，也方便 debug）
    payload['unlink_all'] = false;
    return payload;
  }
}

/// 解除使用者與 session(bag) 的綁定回傳：POST /v1/users/{user_code}/sessions/unlink
@immutable
class UnlinkUserSessionResponse {
  const UnlinkUserSessionResponse({
    required this.userCode,
    required this.mode,
    required this.unlinkedSessions,
    required this.failed,
  });

  final String userCode;
  final String mode; // 'batch'
  final int unlinkedSessions;
  final List<String> failed;

  factory UnlinkUserSessionResponse.fromJson(Map<String, Object?> json) {
    final failedRaw = json['failed'];
    return UnlinkUserSessionResponse(
      userCode: stringValue(json['user_code']) ?? '',
      mode: stringValue(json['mode']) ?? 'batch',
      unlinkedSessions: intValue(json['unlinked_sessions']) ?? 0,
      failed: failedRaw is List
          ? failedRaw
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────

String? _stringOrNull(String? raw) {
  final trimmed = raw?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
