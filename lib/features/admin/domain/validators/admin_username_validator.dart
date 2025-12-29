/// 管理員 username 規則（domain layer）。
///
/// 後端規則：3~64 字，僅限英數與 . _ -
const int adminUsernameMinLength = 3;
const int adminUsernameMaxLength = 64;

final RegExp adminUsernameRegex = RegExp(r'^[A-Za-z0-9._-]+$');

bool isValidAdminUsername(String value) {
  final trimmed = value.trim();
  if (trimmed.length < adminUsernameMinLength ||
      trimmed.length > adminUsernameMaxLength) {
    return false;
  }
  return adminUsernameRegex.hasMatch(trimmed);
}


