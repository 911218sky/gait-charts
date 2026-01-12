import 'package:flutter/foundation.dart';

/// JSON 解析工具函數。
///
/// 提供安全的型別轉換，處理後端回傳的各種資料格式。

/// 安全取得字串值，自動 trim 並處理空值。
String? stringValue(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value == null) {
    return null;
  }
  final asString = value.toString().trim();
  return asString.isEmpty ? null : asString;
}

/// 安全取得字串列表值，自動去重並移除空值。
List<String>? stringListValue(Object? value) {
  if (value is! List) {
    return null;
  }
  final out = <String>[];
  final seen = <String>{};
  for (final item in value) {
    final s = item?.toString().trim() ?? '';
    if (s.isEmpty) continue;
    if (seen.add(s)) {
      out.add(s);
    }
  }
  return out.isEmpty ? null : out;
}

/// 安全取得整數值。
int? intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final raw = stringValue(value);
  if (raw == null) {
    return null;
  }
  return int.tryParse(raw);
}

/// 安全取得浮點數值。
double? doubleValue(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  final raw = stringValue(value);
  if (raw == null) {
    return null;
  }
  return double.tryParse(raw);
}

/// 安全取得布林值。
bool? boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  final raw = stringValue(value)?.toLowerCase();
  if (raw == null) {
    return null;
  }
  if (raw == 'true' || raw == '1' || raw == 'yes') {
    return true;
  }
  if (raw == 'false' || raw == '0' || raw == 'no') {
    return false;
  }
  return null;
}

/// 安全取得 Map 值。
Map<String, Object?>? mapValue(Object? value) {
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return null;
}

/// 解析日期（date-only，忽略時間部分）。
DateTime? parseDate(Object? value) {
  final raw = stringValue(value);
  if (raw == null) {
    return null;
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// 解析完整日期時間。
DateTime? parseDateTime(Object? value) {
  final raw = stringValue(value);
  if (raw == null) {
    return null;
  }
  return DateTime.tryParse(raw);
}

/// 將日期轉為 ISO 格式字串（date-only）。
String toDateIso(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.toIso8601String().split('T').first;
}

/// 正規化 cohort 列表。
///
/// - 移除空值和重複項
/// - 若結果為空，回傳預設值 ['正常人']
List<String> normalizeCohortList(List<String>? raw) {
  final normalized = (raw ?? const <String>[])
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
  if (normalized.isEmpty) {
    return const ['正常人'];
  }
  // 保留插入順序的去重
  final out = <String>[];
  final seen = <String>{};
  for (final c in normalized) {
    if (seen.add(c)) out.add(c);
  }
  return out.isEmpty ? const ['正常人'] : out;
}

/// 檢查是否為預設 cohort。
bool isDefaultCohort(List<String> cohort) {
  return cohort.length == 1 && cohort.first.trim() == '正常人';
}

/// 比較兩個字串列表是否相等。
bool stringListEquals(List<String>? a, List<String>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 比較兩個 double 是否相等（考慮浮點數精度）。
bool doubleEquals(double? a, double? b) {
  if (a == null && b == null) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  return (a - b).abs() < 1e-9;
}

/// 將字串轉為 null（若為空或只有空白）。
String? stringOrNull(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

/// 用於「Create」時的 nested payload 壓縮。
///
/// - 移除 null / 空字串 / 空 list / 空 map
/// - list 內容會轉為 trimmed string 並移除空值
Map<String, Object?>? compactJsonMap(Map<String, Object?>? value) {
  if (value == null) {
    return null;
  }
  final out = <String, Object?>{};
  for (final entry in value.entries) {
    final v = entry.value;
    if (v == null) {
      continue;
    }
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      out[entry.key] = trimmed;
      continue;
    }
    if (v is List) {
      final items = v
          .map((e) => e?.toString().trim())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (items.isEmpty) {
        continue;
      }
      out[entry.key] = items;
      continue;
    }
    if (v is Map) {
      final nested = compactJsonMap(v.cast<String, Object?>());
      if (nested == null) {
        continue;
      }
      out[entry.key] = nested;
      continue;
    }
    out[entry.key] = v;
  }
  return out.isEmpty ? null : out;
}

/// 用於「Update」時的 nested section diff。
///
/// - 只考慮 next 內有提供的 key（缺 key 代表不更新）
/// - next 值為 null 表示清空該欄位
/// - nested map 會遞迴 diff，避免覆蓋整包
Map<String, Object?> diffJsonMap(
  Map<String, Object?> prev,
  Map<String, Object?> next,
) {
  final diff = <String, Object?>{};

  for (final entry in next.entries) {
    final key = entry.key;
    final nextValue = entry.value;
    final prevHas = prev.containsKey(key);
    final prevValue = prev[key];

    if (nextValue is Map) {
      final prevMap = prevValue is Map
          ? prevValue.cast<String, Object?>()
          : const <String, Object?>{};
      final nested = diffJsonMap(prevMap, nextValue.cast<String, Object?>());
      if (nested.isNotEmpty) {
        diff[key] = nested;
      }
      continue;
    }

    if (nextValue is List) {
      final prevList = prevValue is List ? prevValue.cast<Object?>() : null;
      final nextList = nextValue.cast<Object?>();
      if (prevList == null || !listEquals(prevList, nextList)) {
        diff[key] = nextValue;
      }
      continue;
    }

    if (!prevHas && nextValue == null) {
      continue;
    }
    if (prevHas && _jsonScalarEquals(prevValue, nextValue)) {
      continue;
    }

    diff[key] = nextValue;
  }

  return diff;
}

bool _jsonScalarEquals(Object? a, Object? b) {
  if (a is num && b is num) {
    return (a.toDouble() - b.toDouble()).abs() < 1e-9;
  }
  return a == b;
}
