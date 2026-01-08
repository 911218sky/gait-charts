import 'package:flutter/foundation.dart';

/// 使用者（個案）基本資料。
@immutable
class UserItem {
  const UserItem({
    required this.userCode,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
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

  final String userCode;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 問卷/收案日期（date-only）。
  final DateTime? assessmentDate;

  final String? sex;
  final int? ageYears;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? educationLevel;

  /// 使用者族群分類（可多選）。
  ///
  /// 後端預設：["正常人"]
  final List<String> cohort;

  /// 後端回傳的 nested sections 目前以 Map 保存，避免前端硬綁欄位。
  final Map<String, Object?>? diagnosis;
  final Map<String, Object?>? medicalHistory;
  final Map<String, Object?>? symptoms;
  final Map<String, Object?>? lifestyle;

  final String? notes;

  factory UserItem.fromJson(Map<String, Object?> json) {
    return UserItem(
      userCode: _stringValue(json['user_code']) ?? '',
      name: _stringValue(json['name']) ?? '',
      assessmentDate: _parseDate(json['assessment_date']),
      sex: _stringValue(json['sex']),
      ageYears: _intValue(json['age_years']),
      heightCm: _doubleValue(json['height_cm']),
      weightKg: _doubleValue(json['weight_kg']),
      bmi: _doubleValue(json['bmi']),
      educationLevel: _stringValue(json['education_level']),
      cohort: _normalizeCohortList(_stringListValue(json['cohort'])),
      diagnosis: _mapValue(json['diagnosis']),
      medicalHistory: _mapValue(json['medical_history']),
      symptoms: _mapValue(json['symptoms']),
      lifestyle: _mapValue(json['lifestyle']),
      notes: _stringValue(json['notes']),
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDateTime(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'user_code': userCode,
      'name': name,
      'assessment_date': assessmentDate != null
          ? _toDateIso(assessmentDate!)
          : null,
      'sex': sex,
      'age_years': ageYears,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'education_level': educationLevel,
      'cohort': cohort,
      'diagnosis': diagnosis,
      'medical_history': medicalHistory,
      'symptoms': symptoms,
      'lifestyle': lifestyle,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// 使用者綁定的 session(bag) 紀錄。
@immutable
class UserSessionItem {
  const UserSessionItem({
    required this.sessionName,
    required this.npyPath,
    required this.bagPath,
    required this.bagFilename,
    required this.createdAt,
    required this.updatedAt,
    this.userCode,
    this.videoPath,
  });

  final String sessionName;
  final String? userCode;
  final String npyPath;
  final String bagPath;
  /// BAG 檔案名稱（例如：1_1_607.bag）。
  final String bagFilename;
  final String? videoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 是否有影片可播放。
  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;

  factory UserSessionItem.fromJson(Map<String, Object?> json) {
    return UserSessionItem(
      sessionName: _stringValue(json['session_name']) ?? '',
      userCode: _stringValue(json['user_code']),
      npyPath: _stringValue(json['npy_path']) ?? '',
      bagPath: _stringValue(json['bag_path']) ?? '',
      bagFilename: _stringValue(json['bag_filename']) ?? '',
      videoPath: _stringValue(json['video_path']),
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDateTime(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// 取得使用者詳情的回傳：包含 user + sessions。
@immutable
class UserDetailResponse {
  const UserDetailResponse({required this.user, required this.sessions});

  final UserItem user;
  final List<UserSessionItem> sessions;

  factory UserDetailResponse.fromJson(Map<String, Object?> json) {
    final userRaw = json['user'];
    final sessionsRaw = json['sessions'];

    return UserDetailResponse(
      user: userRaw is Map
          ? UserItem.fromJson(userRaw.cast<String, Object?>())
          : UserItem(
              userCode: '',
              name: '',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
      sessions: sessionsRaw is List
          ? sessionsRaw
                .whereType<Map<String, Object?>>()
                .map(UserSessionItem.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

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
    final normalizedCohort = _normalizeCohortList(cohort);
    final payload = <String, Object?>{
      'name': name.trim(),
      if (_stringOrNull(userCode) != null) 'user_code': _stringOrNull(userCode),
      if (assessmentDate != null)
        'assessment_date': _toDateIso(assessmentDate!),
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
    final nextCohort = _normalizeCohortList(cohort);
    setIfChanged<List<String>>(
      'cohort',
      nextCohort,
      _normalizeCohortList(original.cohort),
      equals: _stringListEquals,
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
      final diff = _diffJsonMap(prev ?? const <String, Object?>{}, next);
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
      assessmentDate != null ? _toDateIso(assessmentDate!) : null,
      original.assessmentDate != null
          ? _toDateIso(original.assessmentDate!)
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
    final normalizedCohort = _normalizeCohortList(cohort);

    final code = _stringOrNull(userCode);
    if (code != null) {
      payload['user_code'] = code;
    }

    if (assessmentDate != null) {
      payload['assessment_date'] = _toDateIso(assessmentDate!);
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
      userCode: _stringValue(json['user_code']) ?? '',
      mode: _stringValue(json['mode']) ?? 'batch',
      unlinkedSessions: _intValue(json['unlinked_sessions']) ?? 0,
      failed: failedRaw is List
          ? failedRaw
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

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
      userCode: _stringValue(json['user_code']) ?? '',
      deletedUser: _boolValue(json['deleted_user']) ?? false,
      unlinkedSessions: _intValue(json['unlinked_sessions']) ?? 0,
      deletedSessions: _intValue(json['deleted_sessions']) ?? 0,
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
      totalRequested: _intValue(json['total_requested']) ?? 0,
      deletedUsers: _intValue(json['deleted_users']) ?? 0,
      totalUnlinkedSessions: _intValue(json['total_unlinked_sessions']) ?? 0,
      totalDeletedSessions: _intValue(json['total_deleted_sessions']) ?? 0,
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
      userCode: _stringValue(json['user_code']) ?? '',
      deletedUser: _boolValue(json['deleted_user']) ?? false,
      unlinkedSessions: _intValue(json['unlinked_sessions']) ?? 0,
      deletedSessions: _intValue(json['deleted_sessions']) ?? 0,
    );
  }
}

/// 使用者列表單筆資料
@immutable
class UserListItem {
  const UserListItem({
    required this.userCode,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.cohort = const ['正常人'],
  });

  final String userCode;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> cohort;

  factory UserListItem.fromJson(Map<String, Object?> json) {
    return UserListItem(
      userCode: _stringValue(json['user_code']) ?? '',
      name: _stringValue(json['name']) ?? '',
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDateTime(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      cohort: _normalizeCohortList(_stringListValue(json['cohort'])),
    );
  }
}

/// 使用者名稱搜尋（前綴）回傳項目。
///
/// 用於 `/users/search`：只回傳可用來「顯示清單 + 選擇 user_code」的最小資訊。
@immutable
class UserSearchSuggestionItem {
  const UserSearchSuggestionItem({
    required this.userCode,
    required this.name,
    required this.createdAt,
    this.cohort = const ['正常人'],
  });

  final String userCode;
  final String name;
  final DateTime createdAt;
  final List<String> cohort;

  factory UserSearchSuggestionItem.fromJson(Map<String, Object?> json) {
    return UserSearchSuggestionItem(
      userCode: _stringValue(json['user_code']) ?? '',
      name: _stringValue(json['name']) ?? '',
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      cohort: _normalizeCohortList(_stringListValue(json['cohort'])),
    );
  }
}

/// 族群統計項目（GET /v1/users/cohorts）。
@immutable
class UserCohortStat {
  const UserCohortStat({required this.cohort, required this.userCount});

  final String cohort;
  final int userCount;

  factory UserCohortStat.fromJson(Map<String, Object?> json) {
    return UserCohortStat(
      cohort: _stringValue(json['cohort']) ?? '',
      userCount: _intValue(json['user_count']) ?? 0,
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
      totalCohorts: _intValue(json['total_cohorts']) ?? 0,
    );
  }
}

/// 使用者名稱搜尋（前綴）回傳。
@immutable
class UserSearchSuggestionResponse {
  const UserSearchSuggestionResponse({
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
  final List<UserSearchSuggestionItem> items;

  bool get canLoadMore => page < totalPages;

  factory UserSearchSuggestionResponse.fromJson(Map<String, Object?> json) {
    final itemsRaw = json['items'];
    return UserSearchSuggestionResponse(
      total: _intValue(json['total']) ?? 0,
      page: _intValue(json['page']) ?? 1,
      pageSize: _intValue(json['page_size']) ?? 20,
      totalPages: _intValue(json['total_pages']) ?? 0,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map<String, Object?>>()
                .map(UserSearchSuggestionItem.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

/// 使用者列表回傳（分頁）。
@immutable
class UserListResponse {
  const UserListResponse({
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
  final List<UserListItem> items;

  bool get canLoadMore => page < totalPages;

  factory UserListResponse.fromJson(Map<String, Object?> json) {
    final itemsRaw = json['items'];
    return UserListResponse(
      total: _intValue(json['total']) ?? 0,
      page: _intValue(json['page']) ?? 1,
      pageSize: _intValue(json['page_size']) ?? 20,
      totalPages: _intValue(json['total_pages']) ?? 0,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map<String, Object?>>()
                .map(UserListItem.fromJson)
                .toList(growable: false)
          : const [],
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
      found: _boolValue(json['found']) ?? false,
      user: userRaw is Map
          ? UserItem.fromJson(userRaw.cast<String, Object?>())
          : null,
      sessions: sessionsRaw is List
          ? sessionsRaw
                .whereType<Map<String, Object?>>()
                .map(UserSessionItem.fromJson)
                .toList(growable: false)
          : const [],
      totalSessions: _intValue(json['total_sessions']) ?? 0,
    );
  }
}

bool _doubleEquals(double? a, double? b) {
  if (a == null && b == null) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  return (a - b).abs() < 1e-9;
}

String? _stringOrNull(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _stringValue(Object? value) {
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

List<String>? _stringListValue(Object? value) {
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

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final raw = _stringValue(value);
  if (raw == null) {
    return null;
  }
  return int.tryParse(raw);
}

double? _doubleValue(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  final raw = _stringValue(value);
  if (raw == null) {
    return null;
  }
  return double.tryParse(raw);
}

bool? _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  final raw = _stringValue(value)?.toLowerCase();
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

Map<String, Object?>? _mapValue(Object? value) {
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return null;
}

List<String> _normalizeCohortList(List<String>? raw) {
  // 族群最少保留 1 個；若未提供/清空，回到預設。
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

bool _isDefaultCohort(List<String> cohort) {
  return cohort.length == 1 && cohort.first.trim() == '正常人';
}

bool _stringListEquals(List<String>? a, List<String>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 用於「Create」時的 nested payload 壓縮：
/// - 移除 null / 空字串 / 空 list / 空 map
/// - list 內容會轉為 trimmed string 並移除空值
Map<String, Object?>? _compactJsonMap(Map<String, Object?>? value) {
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
      final nested = _compactJsonMap(v.cast<String, Object?>());
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

/// 用於「Update」時的 nested section diff：
/// - 只考慮 next 內有提供的 key（缺 key 代表不更新）
/// - next 值為 null 表示清空該欄位
/// - nested map 會遞迴 diff，避免覆蓋整包
Map<String, Object?> _diffJsonMap(
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
      final nested = _diffJsonMap(prevMap, nextValue.cast<String, Object?>());
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
      // 原本沒有值，且 next 也沒有提供有效值：不需要送出
      continue;
    }
    if (prevHas && _jsonScalarEquals(prevValue, nextValue)) {
      continue;
    }

    // changed (包含設為 null 以清空)
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

DateTime? _parseDate(Object? value) {
  final raw = _stringValue(value);
  if (raw == null) {
    return null;
  }
  // 後端 date 欄位通常為 yyyy-MM-dd。
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _parseDateTime(Object? value) {
  final raw = _stringValue(value);
  if (raw == null) {
    return null;
  }
  return DateTime.tryParse(raw);
}

String _toDateIso(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.toIso8601String().split('T').first;
}
