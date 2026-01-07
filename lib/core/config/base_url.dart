/// baseUrl 驗證與正規化。
///
/// 處理規則：
/// - trim 空白
/// - 移除尾端多餘的 `/`
/// - 驗證為有效的 http/https URL
///
/// 是否包含 `/v1` 由使用者決定，不同後端版本可能不同。
String normalizeBaseUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('baseUrl 不可為空。');
  }

  // 移除尾端 `/`，避免 path 拼接時產生 `//`
  var normalized = trimmed;
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw const FormatException('baseUrl 格式不正確，請輸入 http/https 的完整網址。');
  }

  return normalized;
}


