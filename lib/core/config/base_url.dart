/// baseUrl 的基礎驗證與正規化工具。
///
/// 規則：
/// - 會 trim
/// - 會移除尾端多餘的 `/`
/// - 必須是可解析的 Uri 且包含 http/https scheme
///
/// 注意：是否一定要包含 `/v1` 由使用者自行決定（不同後端版本可能不同）。
String normalizeBaseUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('baseUrl 不可為空。');
  }

  // 移除尾端的 '/'，避免 path 拼接時出現 '//'。
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


