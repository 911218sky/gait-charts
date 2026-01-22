import 'package:flutter/foundation.dart';

@immutable
class AdminPublic {
  const AdminPublic({
    required this.adminCode,
    required this.username,
    required this.createdAt,
    this.invitedByCode,
  });

  final String adminCode;
  final String username;
  final String? invitedByCode;
  final DateTime createdAt;

  factory AdminPublic.fromJson(Map<String, Object?> json) {
    return AdminPublic(
      adminCode: _stringValue(json['admin_code']) ?? '',
      username: _stringValue(json['username']) ?? '',
      invitedByCode: _stringValue(json['invited_by_code']),
      createdAt: _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

@immutable
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.admin,
  });

  final String token;
  final DateTime expiresAt;
  final AdminPublic admin;
}

@immutable
class AdminListItem {
  const AdminListItem({
    required this.adminCode,
    required this.username,
    required this.createdAt,
    required this.canDelete,
    this.invitedByCode,
  });

  final String adminCode;
  final String username;
  final String? invitedByCode;
  final DateTime createdAt;
  final bool canDelete;

  factory AdminListItem.fromJson(Map<String, Object?> json) {
    return AdminListItem(
      adminCode: _stringValue(json['admin_code']) ?? '',
      username: _stringValue(json['username']) ?? '',
      invitedByCode: _stringValue(json['invited_by_code']),
      createdAt: _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      canDelete: _boolValue(json['can_delete']) ?? false,
    );
  }
}

@immutable
class AdminListResponse {
  const AdminListResponse({
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
  final List<AdminListItem> items;

  factory AdminListResponse.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    return AdminListResponse(
      total: _intValue(json['total']) ?? 0,
      page: _intValue(json['page']) ?? 1,
      pageSize: _intValue(json['page_size']) ?? 0,
      totalPages: _intValue(json['total_pages']) ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, Object?>>()
              .map(AdminListItem.fromJson)
              .toList(growable: false)
          : const <AdminListItem>[],
    );
  }
}

@immutable
class InvitationCode {
  const InvitationCode({
    required this.code,
    required this.expiresAt,
  });

  final String code;
  final DateTime expiresAt;

  factory InvitationCode.fromJson(Map<String, Object?> json) {
    return InvitationCode(
      code: _stringValue(json['code']) ?? '',
      expiresAt: _parseDateTime(json['expires_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

@immutable
class DeleteAdminResult {
  const DeleteAdminResult({
    required this.adminCode,
    required this.deleted,
  });

  final String adminCode;
  final bool deleted;

  factory DeleteAdminResult.fromJson(Map<String, Object?> json) {
    return DeleteAdminResult(
      adminCode: _stringValue(json['admin_code']) ?? '',
      deleted: _boolValue(json['deleted']) ?? false,
    );
  }
}

@immutable
class LogoutResult {
  const LogoutResult({
    required this.loggedOut,
    required this.sessionRevoked,
  });

  final bool loggedOut;
  final bool sessionRevoked;

  factory LogoutResult.fromJson(Map<String, Object?> json) {
    return LogoutResult(
      loggedOut: _boolValue(json['logged_out']) ?? false,
      sessionRevoked: _boolValue(json['session_revoked']) ?? false,
    );
  }
}

String? _stringValue(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return null;
}

DateTime? _parseDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}