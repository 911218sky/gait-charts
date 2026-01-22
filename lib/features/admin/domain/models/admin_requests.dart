import 'package:flutter/foundation.dart';

@immutable
class LoginRequest {
  const LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, Object?> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

@immutable
class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.password,
    this.inviteCode,
  });

  final String username;
  final String password;
  final String? inviteCode;

  Map<String, Object?> toJson() {
    return {
      'username': username,
      'password': password,
      if (inviteCode != null && inviteCode!.trim().isNotEmpty)
        'invite_code': inviteCode!.trim(),
    };
  }
}

@immutable
class InvitationCreateRequest {
  const InvitationCreateRequest({required this.expiresInHours});

  final int expiresInHours;

  Map<String, Object?> toJson() {
    return {
      'expires_in_hours': expiresInHours,
    };
  }
}

@immutable
class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  final String oldPassword;
  final String newPassword;

  Map<String, Object?> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
    };
  }
}

@immutable
class AdminUpdateMeRequest {
  const AdminUpdateMeRequest({required this.username});

  final String username;

  Map<String, Object?> toJson() {
    return {
      'username': username.trim(),
    };
  }
}

