import 'package:flutter/foundation.dart';
import 'package:gait_charts/features/dashboard/domain/utils/json_parsing_utils.dart';
import 'user_item.dart';

/// 用於「建立/編輯」的表單草稿。
///
/// 注意：
/// - Create：用 [toCreateJson]，只輸出非空欄位。
/// - Update：用 [toPatchJson]，只輸出「有變更」的欄位（包含要清空的 null）。
@immutable
class UserProfileDraft {
  const UserProfileDraft({
    required this.name,
    this.userCode,
    this.assessmentDate,
    this.sex,
    this.ageYears,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.educationLevel,
    this.cohort = const ['正常人'],
    this.diagnosis,
    this.medicalHistory,
    this.symptoms,
    this.lifestyle,
    this.notes,
  });

  final String? userCode;
  final String name;
  final DateTime? assessmentDate;
  final String? sex;
  final int? ageYears;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? educationLevel;
  final List<String> cohort;
  final Map<String, Object?>? diagnosis;
  final Map<String, Object?>? medicalHistory;
  final Map<String, Object?>? symptoms;
  final Map<String, Object?>? lifestyle;
  final String? notes;

  Map<String, Object?> toCreateJson() {
    final normalizedCohort = normalizeCohortList(cohort);
    final payload = <String, Object?>{
      'name': name.trim(),
      if (_stringOrNull(userCode) != null) 'user_code': _stringOrNull(userCode),
      if (assessmentDate != null)
        'assessment_date': toDateIso(assessmentDate!),
      if (_stringOrNull(sex) != null) 'sex': _stringOrNull(sex),
      if (ageYears != null) 'age_years': ageYears,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bmi != null) 'bmi': bmi,
      if (_stringOrNull(educationLevel) != null)
        'education_level': _stringOrNull(educationLevel),
      if (!_isDefaultCohort(normalizedCohort)) 'cohort': normalizedCohort,
      if (_compactJsonMap(diagnosis) != null)
        'diagnosis': _compactJsonMap(diagnosis),
      if (_compactJsonMap(medicalHistory) != null)
        'medical_history': _compactJsonMap(medicalHistory),
      if (_compactJsonMap(symptoms) != null)
        'symptoms': _compactJsonMap(symptoms),
      if (_compactJsonMap(lifestyle) != null)
        'lifestyle': _compactJsonMap(lifestyle),
      if (_stringOrNull(notes) != null) 'notes': _stringOrNull(notes),
    };

    return payload;
  }

  /// 以「差異」生成 PATCH payload。
  ///
  /// - 欄位有變更才會輸出
  /// - 若要清空欄位，請把該欄位設為 null / 空字串，會輸出 key: null
  Map<String, Object?> toPatchJson({required UserItem original}) {
    final patch = <String, Object?>{};

    void setIfChanged<T>(
      String key,
      T? next,
      T? prev, {
      bool Function(T?, T?)? equals,
    }) {
      final isEqual = equals != null ? equals(next, prev) : next == prev;
      if (isEqual) {
        return;
      }
      patch[key] = next;
    }

    final nextName = name.trim();
    if (nextName.isNotEmpty && nextName != original.name) {
      patch['name'] = nextName;
    }

    setIfChanged<String?>(
      'sex',
      _stringOrNull(sex),
      _stringOrNull(original.sex),
    );

    setIfChanged<int?>('age_years', ageYears, original.ageYears);

    setIfChanged<double?>(
      'height_cm',
      heightCm,
      original.heightCm,
      equals: _doubleEquals,
    );

    setIfChanged<double?>(
      'weight_kg',
      weightKg,
      original.weightKg,
      equals: _doubleEquals,
    );

    setIfChanged<double?>('bmi', bmi, original.bmi, equals: _doubleEquals);

    setIfChanged<String?>(
      'education_level',
      _stringOrNull(educationLevel),
      _stringOrNull(original.educationLevel),
    );

    // cohort：後端為覆蓋更新（非 merge）。
    final nextCohort = normalizeCohortList(cohort);
    setIfChanged<List<String>>(
      'cohort',
      nextCohort,
      normalizeCohortList(original.cohort),
      equals: stringListEquals,
    );

    setIfChanged<String?>(
      'notes',
      _stringOrNull(notes),
      _stringOrNull(original.notes),
    );

    void setNestedSectionPatch(
      String key, {
      required Map<String, Object?>? next,
      required Map<String, Object?>? prev,
    }) {
      if (next == null) {
        // next=null 代表整包清空（若原本就沒有，則略過）
        if (prev != null) {
          patch[key] = null;
        }
        return;
      }
      final diff = diffJsonMap(prev ?? const <String, Object?>{}, next);
      if (diff.isEmpty) {
        return;
      }
      patch[key] = diff;
    }

    setNestedSectionPatch(
      'diagnosis',
      next: diagnosis,
      prev: original.diagnosis,
    );
    setNestedSectionPatch(
      'medical_history',
      next: medicalHistory,
      prev: original.medicalHistory,
    );
    setNestedSectionPatch('symptoms', next: symptoms, prev: original.symptoms);
    setNestedSectionPatch(
      'lifestyle',
      next: lifestyle,
      prev: original.lifestyle,
    );

    setIfChanged<String?>(
      'assessment_date',
      assessmentDate != null ? toDateIso(assessmentDate!) : null,
      original.assessmentDate != null
          ? toDateIso(original.assessmentDate!)
          : null,
    );

    return patch;
  }
}

/// 建立使用者（個案）請求：POST /v1/users
@immutable
class UserCreateRequest {
  const UserCreateRequest({
    required this.name,
    this.userCode,
    this.assessmentDate,
    this.sex,
    this.ageYears,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.educationLevel,
    this.cohort = const ['正常人'],
    this.diagnosis,
    this.medicalHistory,
    this.symptoms,
    this.lifestyle,
    this.notes,
  });

  final String? userCode;
  final String name;
  final DateTime? assessmentDate;
  final String? sex;
  final int? ageYears;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? educationLevel;
  final List<String> cohort;
  final Map<String, Object?>? diagnosis;
  final Map<String, Object?>? medicalHistory;
  final Map<String, Object?>? symptoms;
  final Map<String, Object?>? lifestyle;
  final String? notes;

  factory UserCreateRequest.fromDraft(UserProfileDraft draft) {
    return UserCreateRequest(
      userCode: draft.userCode,
      name: draft.name,
      assessmentDate: draft.assessmentDate,
      sex: draft.sex,
      ageYears: draft.ageYears,
      heightCm: draft.heightCm,
      weightKg: draft.weightKg,
      bmi: draft.bmi,
      educationLevel: draft.educationLevel,
      cohort: draft.cohort,
      diagnosis: draft.diagnosis,
      medicalHistory: draft.medicalHistory,
      symptoms: draft.symptoms,
      lifestyle: draft.lifestyle,
      notes: draft.notes,
    );
  }

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{'name': name.trim()};
    final normalizedCohort = normalizeCohortList(cohort);

    final code = _stringOrNull(userCode);
    if (code != null) {
      payload['user_code'] = code;
    }

    if (assessmentDate != null) {
      payload['assessment_date'] = toDateIso(assessmentDate!);
    }

    final normalizedSex = _stringOrNull(sex);
    if (normalizedSex != null) {
      payload['sex'] = normalizedSex;
    }

    if (ageYears != null) {
      payload['age_years'] = ageYears;
    }
    if (heightCm != null) {
      payload['height_cm'] = heightCm;
    }
    if (weightKg != null) {
      payload['weight_kg'] = weightKg;
    }
    if (bmi != null) {
      payload['bmi'] = bmi;
    }

    final normalizedEducation = _stringOrNull(educationLevel);
    if (normalizedEducation != null) {
      payload['education_level'] = normalizedEducation;
    }

    if (!_isDefaultCohort(normalizedCohort)) {
      payload['cohort'] = normalizedCohort;
    }

    final diagnosisPayload = _compactJsonMap(diagnosis);
    if (diagnosisPayload != null) {
      payload['diagnosis'] = diagnosisPayload;
    }
    final medicalHistoryPayload = _compactJsonMap(medicalHistory);
    if (medicalHistoryPayload != null) {
      payload['medical_history'] = medicalHistoryPayload;
    }
    final symptomsPayload = _compactJsonMap(symptoms);
    if (symptomsPayload != null) {
      payload['symptoms'] = symptomsPayload;
    }
    final lifestylePayload = _compactJsonMap(lifestyle);
    if (lifestylePayload != null) {
      payload['lifestyle'] = lifestylePayload;
    }

    final normalizedNotes = _stringOrNull(notes);
    if (normalizedNotes != null) {
      payload['notes'] = normalizedNotes;
    }

    return payload;
  }
}

/// 更新使用者資料（PATCH）請求：PATCH /v1/users/{user_code}
@immutable
class UserUpdateRequest {
  const UserUpdateRequest._(this._patch);

  final Map<String, Object?> _patch;

  bool get isEmpty => _patch.isEmpty;

  Map<String, Object?> toJson() => _patch;

  factory UserUpdateRequest.diff({
    required UserItem original,
    required UserProfileDraft next,
  }) {
    return UserUpdateRequest._(next.toPatchJson(original: original));
  }
}

// ─────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────

bool _doubleEquals(double? a, double? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return (a - b).abs() < 1e-9;
}

String? _stringOrNull(String? raw) {
  final trimmed = raw?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

bool _isDefaultCohort(List<String> cohort) {
  return cohort.length == 1 && cohort.first.trim() == '正常人';
}

/// 用於「Create」時的 nested payload 壓縮：
/// - 移除 null / 空字串 / 空 list / 空 map
/// - list 內容會轉為 trimmed string 並移除空值
Map<String, Object?>? _compactJsonMap(Map<String, Object?>? value) {
  if (value == null) return null;
  final out = <String, Object?>{};
  for (final entry in value.entries) {
    final v = entry.value;
    if (v == null) continue;
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) continue;
      out[entry.key] = trimmed;
      continue;
    }
    if (v is List) {
      final items = v
          .map((e) => e?.toString().trim())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (items.isEmpty) continue;
      out[entry.key] = items;
      continue;
    }
    if (v is Map) {
      final nested = _compactJsonMap(v.cast<String, Object?>());
      if (nested == null) continue;
      out[entry.key] = nested;
      continue;
    }
    out[entry.key] = v;
  }
  return out.isEmpty ? null : out;
}
