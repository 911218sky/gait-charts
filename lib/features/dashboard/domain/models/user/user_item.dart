import 'package:flutter/foundation.dart';
import 'package:gait_charts/features/dashboard/domain/utils/json_parsing_utils.dart';

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
      userCode: stringValue(json['user_code']) ?? '',
      name: stringValue(json['name']) ?? '',
      assessmentDate: parseDate(json['assessment_date']),
      sex: stringValue(json['sex']),
      ageYears: intValue(json['age_years']),
      heightCm: doubleValue(json['height_cm']),
      weightKg: doubleValue(json['weight_kg']),
      bmi: doubleValue(json['bmi']),
      educationLevel: stringValue(json['education_level']),
      cohort: normalizeCohortList(stringListValue(json['cohort'])),
      diagnosis: mapValue(json['diagnosis']),
      medicalHistory: mapValue(json['medical_history']),
      symptoms: mapValue(json['symptoms']),
      lifestyle: mapValue(json['lifestyle']),
      notes: stringValue(json['notes']),
      createdAt:
          parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseDateTime(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'user_code': userCode,
      'name': name,
      'assessment_date': assessmentDate != null
          ? toDateIso(assessmentDate!)
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
      sessionName: stringValue(json['session_name']) ?? '',
      userCode: stringValue(json['user_code']),
      npyPath: stringValue(json['npy_path']) ?? '',
      bagPath: stringValue(json['bag_path']) ?? '',
      bagFilename: stringValue(json['bag_filename']) ?? '',
      videoPath: stringValue(json['video_path']),
      createdAt:
          parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseDateTime(json['updated_at']) ??
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
