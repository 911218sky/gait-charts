import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 新增 / 編輯使用者的表單 Dialog。
class UserProfileFormDialog extends StatefulWidget {
  const UserProfileFormDialog({super.key}) : user = null;

  const UserProfileFormDialog.edit({required this.user, super.key})
    : assert(user != null);

  final UserItem? user;

  @override
  State<UserProfileFormDialog> createState() => _UserProfileFormDialogState();
}

class _UserProfileFormDialogState extends State<UserProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _userCodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _sexController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _bmiController;
  late final TextEditingController _educationController;
  late final TextEditingController _notesController;
  late final TextEditingController _dateDisplayController;

  DateTime? _assessmentDate;

  // ==========
  // 診斷資訊
  // ==========
  late final TextEditingController _diagDiagnosisController;
  late final TextEditingController _diagBodyPartController;
  late final TextEditingController _diagDiseaseController;
  late final TextEditingController _diagDiagnosisTypeController;
  late final TextEditingController _diagAffectedSideController;
  late final TextEditingController _diagOnsetDateController;
  DateTime? _diagOnsetDate;
  bool? _diagIsRecurrent;
  bool? _diagHasAphasia;

  // ==========
  // 症狀
  // ==========
  List<String> _symptomTags = const [];
  late final TextEditingController _painLocationController;
  late final TextEditingController _painSideController;
  late final TextEditingController _painScoreController;
  late final TextEditingController _fallCountController;
  late final TextEditingController _lastFallDateController;
  DateTime? _lastFallDate;

  // ==========
  // 生活習慣
  // ==========
  bool? _regularHealthCheck;
  bool? _regularDentalCheck;
  bool? _smoking;
  bool? _drinking;
  late final TextEditingController _drinkingFrequencyController;
  late final TextEditingController _drinkingAmountController;
  late final TextEditingController _exerciseHabitController;
  List<String> _exerciseTypes = const [];
  bool? _vigorous10min;
  bool? _vigorous60minPerWeek;
  bool? _moderate10min;
  late final TextEditingController _moderateDaysPerWeekController;
  late final TextEditingController _moderateMinutesPerDayController;

  // ==========
  // 醫療史 / 治療 / 用藥
  // ==========
  late final TextEditingController _relevantExamsController;
  late final TextEditingController _examNotesController;
  late final TextEditingController _otherDiseasesController;
  bool? _hadSurgery;
  late final TextEditingController _surgeryTypeController;
  late final TextEditingController _surgeryDateController;
  DateTime? _surgeryDate;
  bool? _pt;
  bool? _ot;
  bool? _st;
  late final TextEditingController _selfPayItemsController;
  late final TextEditingController _otherItemsController;
  List<String> _medications = const [];
  bool? _medicationAdherence;
  late final TextEditingController _familyHistoryController;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    _userCodeController = TextEditingController(text: user?.userCode ?? '');
    _nameController = TextEditingController(text: user?.name ?? '');
    _sexController = TextEditingController(text: user?.sex ?? '');
    _ageController = TextEditingController(
      text: user?.ageYears != null ? user!.ageYears.toString() : '',
    );
    _heightController = TextEditingController(
      text: user?.heightCm != null ? user!.heightCm!.toString() : '',
    );
    _weightController = TextEditingController(
      text: user?.weightKg != null ? user!.weightKg!.toString() : '',
    );
    _bmiController = TextEditingController(
      text: user?.bmi != null ? user!.bmi!.toString() : '',
    );
    _educationController = TextEditingController(
      text: user?.educationLevel ?? '',
    );
    _notesController = TextEditingController(text: user?.notes ?? '');

    // nested sections
    final diagnosis = user?.diagnosis;
    _diagDiagnosisController = TextEditingController(
      text: _mapString(diagnosis, 'diagnosis'),
    );
    _diagBodyPartController = TextEditingController(
      text: _mapString(diagnosis, 'body_part'),
    );
    _diagDiseaseController = TextEditingController(
      text: _mapString(diagnosis, 'disease'),
    );
    _diagDiagnosisTypeController = TextEditingController(
      text: _mapString(diagnosis, 'diagnosis_type'),
    );
    _diagAffectedSideController = TextEditingController(
      text: _mapString(diagnosis, 'affected_side'),
    );
    _diagOnsetDate = _mapDate(diagnosis, 'onset_date');
    _diagOnsetDateController = TextEditingController();
    _updateDiagnosisOnsetDateDisplay();
    _diagIsRecurrent = _mapBool(diagnosis, 'is_recurrent');
    _diagHasAphasia = _mapBool(diagnosis, 'has_aphasia');

    final symptomInfo = user?.symptoms;
    _symptomTags = _mapStringList(symptomInfo, 'symptoms');
    _painLocationController = TextEditingController(
      text: _mapString(symptomInfo, 'pain_location'),
    );
    _painSideController = TextEditingController(
      text: _mapString(symptomInfo, 'pain_side'),
    );
    _painScoreController = TextEditingController(
      text: _mapInt(symptomInfo, 'pain_score')?.toString() ?? '',
    );
    _fallCountController = TextEditingController(
      text: _mapInt(symptomInfo, 'fall_count')?.toString() ?? '',
    );
    _lastFallDate = _mapDate(symptomInfo, 'last_fall_date');
    _lastFallDateController = TextEditingController();
    _updateLastFallDateDisplay();

    final lifestyle = user?.lifestyle;
    _regularHealthCheck = _mapBool(lifestyle, 'regular_health_check');
    _regularDentalCheck = _mapBool(lifestyle, 'regular_dental_check');
    _smoking = _mapBool(lifestyle, 'smoking');
    _drinking = _mapBool(lifestyle, 'drinking');
    _drinkingFrequencyController = TextEditingController(
      text: _mapString(lifestyle, 'drinking_frequency'),
    );
    _drinkingAmountController = TextEditingController(
      text: _mapString(lifestyle, 'drinking_amount'),
    );
    _exerciseHabitController = TextEditingController(
      text: _mapString(lifestyle, 'exercise_habit'),
    );
    _exerciseTypes = _mapStringList(lifestyle, 'exercise_types');
    _vigorous10min = _mapBool(lifestyle, 'vigorous_10min');
    _vigorous60minPerWeek = _mapBool(lifestyle, 'vigorous_60min_per_week');
    _moderate10min = _mapBool(lifestyle, 'moderate_10min');
    _moderateDaysPerWeekController = TextEditingController(
      text: _mapInt(lifestyle, 'moderate_days_per_week')?.toString() ?? '',
    );
    _moderateMinutesPerDayController = TextEditingController(
      text: _mapInt(lifestyle, 'moderate_minutes_per_day')?.toString() ?? '',
    );

    final medicalHistory = user?.medicalHistory;
    _relevantExamsController = TextEditingController(
      text: _mapString(medicalHistory, 'relevant_exams'),
    );
    _examNotesController = TextEditingController(
      text: _mapString(medicalHistory, 'exam_notes'),
    );
    _otherDiseasesController = TextEditingController(
      text: _mapString(medicalHistory, 'other_diseases'),
    );
    _medications = _mapStringList(medicalHistory, 'medications');
    _medicationAdherence = _mapBool(medicalHistory, 'medication_adherence');
    _familyHistoryController = TextEditingController(
      text: _mapString(medicalHistory, 'family_history'),
    );

    final surgery = _mapMap(medicalHistory, 'surgery');
    _hadSurgery = _mapBool(surgery, 'had_surgery');
    _surgeryDate = _mapDate(surgery, 'surgery_date');
    _surgeryDateController = TextEditingController();
    _updateSurgeryDateDisplay();
    _surgeryTypeController = TextEditingController(
      text: _mapString(surgery, 'surgery_type'),
    );

    final rehab = _mapMap(medicalHistory, 'rehab_treatment');
    _pt = _mapBool(rehab, 'pt');
    _ot = _mapBool(rehab, 'ot');
    _st = _mapBool(rehab, 'st');
    _selfPayItemsController = TextEditingController(
      text: _mapString(rehab, 'self_pay_items'),
    );
    _otherItemsController = TextEditingController(
      text: _mapString(rehab, 'other_items'),
    );

    _assessmentDate = user?.assessmentDate;
    _dateDisplayController = TextEditingController();
    _updateDateDisplay();
  }

  @override
  void dispose() {
    _userCodeController.dispose();
    _nameController.dispose();
    _sexController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bmiController.dispose();
    _educationController.dispose();
    _notesController.dispose();
    _dateDisplayController.dispose();

    // diagnosis
    _diagDiagnosisController.dispose();
    _diagBodyPartController.dispose();
    _diagDiseaseController.dispose();
    _diagDiagnosisTypeController.dispose();
    _diagAffectedSideController.dispose();
    _diagOnsetDateController.dispose();

    // symptoms
    _painLocationController.dispose();
    _painSideController.dispose();
    _painScoreController.dispose();
    _fallCountController.dispose();
    _lastFallDateController.dispose();

    // lifestyle
    _drinkingFrequencyController.dispose();
    _drinkingAmountController.dispose();
    _exerciseHabitController.dispose();
    _moderateDaysPerWeekController.dispose();
    _moderateMinutesPerDayController.dispose();

    // medical history
    _relevantExamsController.dispose();
    _examNotesController.dispose();
    _otherDiseasesController.dispose();
    _surgeryTypeController.dispose();
    _surgeryDateController.dispose();
    _selfPayItemsController.dispose();
    _otherItemsController.dispose();
    _familyHistoryController.dispose();

    super.dispose();
  }

  void _updateDateDisplay() {
    if (_assessmentDate == null) {
      _dateDisplayController.text = '';
    } else {
      _dateDisplayController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(_assessmentDate!);
    }
  }

  Future<void> _pickAssessmentDate() async {
    final now = DateTime.now();
    final initial = _assessmentDate ?? DateTime(now.year, now.month, now.day);
    final isDark = context.isDark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: context.theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
              headerBackgroundColor: isDark ? const Color(0xFF111111) : context.colorScheme.primary,
              headerForegroundColor: isDark ? Colors.white : Colors.white,
              surfaceTintColor: Colors.transparent,
              dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return isDark ? Colors.white : context.colorScheme.primary;
                }
                return null;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _assessmentDate = DateTime(picked.year, picked.month, picked.day);
      _updateDateDisplay();
    });
  }

  double? _tryParseDouble(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  int? _tryParseInt(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return int.tryParse(normalized);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String? _toDateIso(DateTime? date) {
    if (date == null) {
      return null;
    }
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }

  void _updateDiagnosisOnsetDateDisplay() {
    _diagOnsetDateController.text = _formatDate(_diagOnsetDate);
  }

  void _updateLastFallDateDisplay() {
    _lastFallDateController.text = _formatDate(_lastFallDate);
  }

  void _updateSurgeryDateDisplay() {
    _surgeryDateController.text = _formatDate(_surgeryDate);
  }

  Future<DateTime?> _pickDateValue(DateTime? current) async {
    final now = DateTime.now();
    final initial = current ?? DateTime(now.year, now.month, now.day);
    final isDark = context.isDark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: context.theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
              headerBackgroundColor: isDark ? const Color(0xFF111111) : context.colorScheme.primary,
              headerForegroundColor: isDark ? Colors.white : Colors.white,
              surfaceTintColor: Colors.transparent,
              dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return isDark ? Colors.white : context.colorScheme.primary;
                }
                return null;
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) {
      return null;
    }
    if (picked == null) {
      return null;
    }
    return DateTime(picked.year, picked.month, picked.day);
  }

  Future<void> _pickDiagnosisOnsetDate() async {
    final picked = await _pickDateValue(_diagOnsetDate);
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _diagOnsetDate = picked;
      _updateDiagnosisOnsetDateDisplay();
    });
  }

  Future<void> _pickLastFallDate() async {
    final picked = await _pickDateValue(_lastFallDate);
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _lastFallDate = picked;
      _updateLastFallDateDisplay();
    });
  }

  Future<void> _pickSurgeryDate() async {
    final picked = await _pickDateValue(_surgeryDate);
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _surgeryDate = picked;
      _updateSurgeryDateDisplay();
    });
  }

  String _mapString(Map<String, Object?>? map, String key) {
    final value = map?[key];
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  int? _mapInt(Map<String, Object?>? map, String key) {
    final value = map?[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final raw = value?.toString();
    if (raw == null) {
      return null;
    }
    return int.tryParse(raw);
  }

  bool? _mapBool(Map<String, Object?>? map, String key) {
    final value = map?[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final lowered = value.trim().toLowerCase();
      if (lowered == 'true' || lowered == '1' || lowered == 'yes') {
        return true;
      }
      if (lowered == 'false' || lowered == '0' || lowered == 'no') {
        return false;
      }
    }
    return null;
  }

  DateTime? _mapDate(Map<String, Object?>? map, String key) {
    final raw = map?[key]?.toString();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Map<String, Object?>? _mapMap(Map<String, Object?>? map, String key) {
    final value = map?[key];
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return null;
  }

  List<String> _mapStringList(Map<String, Object?>? map, String key) {
    final value = map?[key];
    if (value is! List) {
      return const [];
    }
    return value
        .map((e) => e?.toString().trim())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  String? _stringOrNull(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _hasAnyValue(Map<String, Object?> map) {
    for (final value in map.values) {
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      if (value is List && value.isEmpty) {
        continue;
      }
      if (value is Map && value.isEmpty) {
        continue;
      }
      return true;
    }
    return false;
  }

  Map<String, Object?>? _buildDiagnosisSection() {
    final payload = <String, Object?>{
      'diagnosis': _stringOrNull(_diagDiagnosisController.text),
      'body_part': _stringOrNull(_diagBodyPartController.text),
      'disease': _stringOrNull(_diagDiseaseController.text),
      'diagnosis_type': _stringOrNull(_diagDiagnosisTypeController.text),
      'affected_side': _stringOrNull(_diagAffectedSideController.text),
      'onset_date': _toDateIso(_diagOnsetDate),
      'is_recurrent': _diagIsRecurrent,
      'has_aphasia': _diagHasAphasia,
    };
    return _hasAnyValue(payload) ? payload : null;
  }

  Map<String, Object?>? _buildSymptomsSection() {
    final payload = <String, Object?>{
      'symptoms': _symptomTags.isNotEmpty ? _symptomTags : null,
      'pain_location': _stringOrNull(_painLocationController.text),
      'pain_side': _stringOrNull(_painSideController.text),
      'pain_score': _tryParseInt(_painScoreController.text),
      'fall_count': _tryParseInt(_fallCountController.text),
      'last_fall_date': _toDateIso(_lastFallDate),
    };
    return _hasAnyValue(payload) ? payload : null;
  }

  Map<String, Object?>? _buildLifestyleSection() {
    final payload = <String, Object?>{
      'regular_health_check': _regularHealthCheck,
      'regular_dental_check': _regularDentalCheck,
      'smoking': _smoking,
      'drinking': _drinking,
      'drinking_frequency': _stringOrNull(_drinkingFrequencyController.text),
      'drinking_amount': _stringOrNull(_drinkingAmountController.text),
      'exercise_habit': _stringOrNull(_exerciseHabitController.text),
      'exercise_types': _exerciseTypes.isNotEmpty ? _exerciseTypes : null,
      'vigorous_10min': _vigorous10min,
      'vigorous_60min_per_week': _vigorous60minPerWeek,
      'moderate_10min': _moderate10min,
      'moderate_days_per_week': _tryParseInt(
        _moderateDaysPerWeekController.text,
      ),
      'moderate_minutes_per_day': _tryParseInt(
        _moderateMinutesPerDayController.text,
      ),
    };
    return _hasAnyValue(payload) ? payload : null;
  }

  Map<String, Object?>? _buildMedicalHistorySection() {
    final surgery = <String, Object?>{
      'had_surgery': _hadSurgery,
      'surgery_date': _toDateIso(_surgeryDate),
      'surgery_type': _stringOrNull(_surgeryTypeController.text),
    };
    final rehab = <String, Object?>{
      'pt': _pt,
      'ot': _ot,
      'st': _st,
      'self_pay_items': _stringOrNull(_selfPayItemsController.text),
      'other_items': _stringOrNull(_otherItemsController.text),
    };
    final payload = <String, Object?>{
      'relevant_exams': _stringOrNull(_relevantExamsController.text),
      'exam_notes': _stringOrNull(_examNotesController.text),
      'other_diseases': _stringOrNull(_otherDiseasesController.text),
      'surgery': _hasAnyValue(surgery) ? surgery : null,
      'rehab_treatment': _hasAnyValue(rehab) ? rehab : null,
      'medications': _medications.isNotEmpty ? _medications : null,
      'medication_adherence': _medicationAdherence,
      'family_history': _stringOrNull(_familyHistoryController.text),
    };
    return _hasAnyValue(payload) ? payload : null;
  }

  void _resetDiagnosisSection() {
    setState(() {
      _diagDiagnosisController.clear();
      _diagBodyPartController.clear();
      _diagDiseaseController.clear();
      _diagDiagnosisTypeController.clear();
      _diagAffectedSideController.clear();
      _diagOnsetDate = null;
      _updateDiagnosisOnsetDateDisplay();
      _diagIsRecurrent = null;
      _diagHasAphasia = null;
    });
  }

  void _resetSymptomsSection() {
    setState(() {
      _symptomTags = const [];
      _painLocationController.clear();
      _painSideController.clear();
      _painScoreController.clear();
      _fallCountController.clear();
      _lastFallDate = null;
      _updateLastFallDateDisplay();
    });
  }

  void _resetMedicalHistorySection() {
    setState(() {
      _relevantExamsController.clear();
      _examNotesController.clear();
      _otherDiseasesController.clear();
      _medications = const [];
      _medicationAdherence = null;
      _familyHistoryController.clear();

      _hadSurgery = null;
      _surgeryDate = null;
      _updateSurgeryDateDisplay();
      _surgeryTypeController.clear();

      _pt = null;
      _ot = null;
      _st = null;
      _selfPayItemsController.clear();
      _otherItemsController.clear();
    });
  }

  void _resetLifestyleSection() {
    setState(() {
      _regularHealthCheck = null;
      _regularDentalCheck = null;
      _smoking = null;
      _drinking = null;
      _drinkingFrequencyController.clear();
      _drinkingAmountController.clear();
      _exerciseHabitController.clear();
      _exerciseTypes = const [];
      _vigorous10min = null;
      _vigorous60minPerWeek = null;
      _moderate10min = null;
      _moderateDaysPerWeekController.clear();
      _moderateMinutesPerDayController.clear();
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final diagnosis = _buildDiagnosisSection();
    final medicalHistory = _buildMedicalHistorySection();
    final symptoms = _buildSymptomsSection();
    final lifestyle = _buildLifestyleSection();

    final draft = UserProfileDraft(
      userCode: _isEdit ? null : _userCodeController.text,
      name: _nameController.text,
      assessmentDate: _assessmentDate,
      sex: _sexController.text,
      ageYears: _tryParseInt(_ageController.text),
      heightCm: _tryParseDouble(_heightController.text),
      weightKg: _tryParseDouble(_weightController.text),
      bmi: _tryParseDouble(_bmiController.text),
      educationLevel: _educationController.text,
      diagnosis: diagnosis,
      medicalHistory: medicalHistory,
      symptoms: symptoms,
      lifestyle: lifestyle,
      notes: _notesController.text,
    );

    context.navigator.pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final size = MediaQuery.sizeOf(context);

    final dialogWidth = (size.width * 0.92).clamp(0.0, 1200.0).toDouble();
    final dialogHeight = (size.height * 0.92).clamp(0.0, 920.0).toDouble();

    // Vercel-like style helpers
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: colors.onSurfaceVariant,
    );

    return Dialog(
      backgroundColor: colors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      // 縮小 inset，讓內容區域更大；但仍保留必要的安全邊距。
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEdit ? '編輯使用者' : '新增使用者',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    AppTooltip(
                      message: '關閉',
                      child: IconButton(
                        onPressed: () => context.navigator.pop(),
                        icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isEdit ? '更新使用者的基本資料與身體數值。' : '建立新的使用者檔案，User Code 可自動產生。',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Row 1: Identity
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _VercelInput(
                        label: 'User Code',
                        controller: _userCodeController,
                        enabled: !_isEdit,
                        placeholder: _isEdit ? null : '留空自動產生',
                        labelStyle: labelStyle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: _VercelInput(
                        label: '姓名',
                        controller: _nameController,
                        labelStyle: labelStyle,
                        validator: (value) =>
                            (value?.trim().isEmpty ?? true) ? '請輸入姓名' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Row 2: Demographics
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VercelInput(
                        label: '性別',
                        controller: _sexController,
                        labelStyle: labelStyle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: '年齡',
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        labelStyle: labelStyle,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = int.tryParse(raw);
                          if (parsed == null) return '整數';
                          if (parsed < 0 || parsed > 130) return '數值不合理';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: '教育程度',
                        controller: _educationController,
                        labelStyle: labelStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Row 3: Metrics
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VercelInput(
                        label: '身高 (cm)',
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        labelStyle: labelStyle,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = _tryParseDouble(raw);
                          if (parsed == null) return '數字';
                          if (parsed <= 0 || parsed > 250) return '數值不合理';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: '體重 (kg)',
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        labelStyle: labelStyle,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = _tryParseDouble(raw);
                          if (parsed == null) return '數字';
                          if (parsed <= 0 || parsed > 500) return '數值不合理';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: 'BMI',
                        controller: _bmiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        placeholder: '自動計算',
                        labelStyle: labelStyle,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = _tryParseDouble(raw);
                          if (parsed == null) return '數字';
                          if (parsed <= 0 || parsed > 100) return '數值不合理';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Row 4: Date
                _VercelInput(
                  label: '收案日期',
                  controller: _dateDisplayController,
                  readOnly: true,
                  onTap: _pickAssessmentDate,
                  placeholder: '未指定',
                  labelStyle: labelStyle,
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 20),

                // Row 5: Notes
                _VercelInput(
                  label: '備註',
                  controller: _notesController,
                  maxLines: 4,
                  labelStyle: labelStyle,
                ),

                const SizedBox(height: 24),

                _SectionCard(
                  title: '診斷資訊',
                  subtitle: '診斷、患側與發病時間（可不填）',
                  initiallyExpanded: true,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _VercelInput(
                            label: '診斷',
                            controller: _diagDiagnosisController,
                            labelStyle: labelStyle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _VercelInput(
                            label: '類型',
                            controller: _diagDiagnosisTypeController,
                            labelStyle: labelStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _VercelInput(
                            label: '部位',
                            controller: _diagBodyPartController,
                            labelStyle: labelStyle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _VercelInput(
                            label: '疾病/疫病',
                            controller: _diagDiseaseController,
                            labelStyle: labelStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _VercelInput(
                            label: '患側',
                            controller: _diagAffectedSideController,
                            labelStyle: labelStyle,
                            placeholder: '例如：L / R',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _VercelInput(
                            label: '發病日期',
                            controller: _diagOnsetDateController,
                            readOnly: true,
                            onTap: _pickDiagnosisOnsetDate,
                            placeholder: '未指定',
                            labelStyle: labelStyle,
                            suffixIcon:                         _DateSuffixIcon(
                          hasValue: _diagOnsetDate != null,
                          onClear: () => setState(() {
                            _diagOnsetDate = null;
                            _updateDiagnosisOnsetDateDisplay();
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _TriBoolField(
                      label: '是否復發',
                      value: _diagIsRecurrent,
                      onChanged: (v) =>
                          setState(() => _diagIsRecurrent = v),
                      labelStyle: labelStyle,
                    ),
                    _TriBoolField(
                      label: '是否失語症',
                      value: _diagHasAphasia,
                      onChanged: (v) => setState(() => _diagHasAphasia = v),
                      labelStyle: labelStyle,
                    ),
                    TextButton.icon(
                      onPressed: _resetDiagnosisSection,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.onSurfaceVariant,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('清空此區塊'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: '症狀',
              subtitle: '疼痛、跌倒與目前困擾症狀（可不填）',
              initiallyExpanded: true,
              children: [
                _ChipsEditor(
                  label: '目前困擾症狀',
                  labelStyle: labelStyle,
                  hintText: '輸入後按 Enter 或「加入」',
                  items: _symptomTags,
                  onChanged: (next) => setState(() => _symptomTags = next),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VercelInput(
                        label: '疼痛部位',
                        controller: _painLocationController,
                        labelStyle: labelStyle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: '疼痛側別',
                        controller: _painSideController,
                        labelStyle: labelStyle,
                        placeholder: '例如：左/右',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VercelInput(
                        label: '疼痛分數 (0-10)',
                        controller: _painScoreController,
                        labelStyle: labelStyle,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = int.tryParse(raw);
                          if (parsed == null) return '整數';
                          if (parsed < 0 || parsed > 10) return '0~10';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: '跌倒次數',
                        controller: _fallCountController,
                        labelStyle: labelStyle,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = int.tryParse(raw);
                          if (parsed == null) return '整數';
                          if (parsed < 0) return '不可為負';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _VercelInput(
                  label: '最近一次跌倒日期',
                  controller: _lastFallDateController,
                  readOnly: true,
                  onTap: _pickLastFallDate,
                  placeholder: '未指定',
                  labelStyle: labelStyle,
                  suffixIcon: _DateSuffixIcon(
                    hasValue: _lastFallDate != null,
                    onClear: () => setState(() {
                      _lastFallDate = null;
                      _updateLastFallDateDisplay();
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetSymptomsSection,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('清空此區塊'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: '醫療史 / 用藥 / 復健',
              subtitle: '檢查、手術、治療與用藥（可不填）',
              children: [
                _VercelInput(
                  label: '相關醫學檢查',
                  controller: _relevantExamsController,
                  labelStyle: labelStyle,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _VercelInput(
                  label: '檢查備註',
                  controller: _examNotesController,
                  labelStyle: labelStyle,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _VercelInput(
                  label: '其它疾病史',
                  controller: _otherDiseasesController,
                  labelStyle: labelStyle,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _ChipsEditor(
                  label: '目前服用藥物',
                  labelStyle: labelStyle,
                  hintText: '輸入藥名後按 Enter 或「加入」',
                  items: _medications,
                  onChanged: (next) => setState(() => _medications = next),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TriBoolField(
                      label: '是否規律服藥',
                      value: _medicationAdherence,
                      onChanged: (v) =>
                          setState(() => _medicationAdherence = v),
                      labelStyle: labelStyle,
                    ),
                    SizedBox(
                      width: 320,
                      child: _VercelInput(
                        label: '家族病史',
                        controller: _familyHistoryController,
                        labelStyle: labelStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: colors.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  '手術資訊',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TriBoolField(
                      label: '是否有開刀史',
                      value: _hadSurgery,
                      onChanged: (v) => setState(() {
                        _hadSurgery = v;
                        if (v != true) {
                          _surgeryDate = null;
                          _updateSurgeryDateDisplay();
                          _surgeryTypeController.clear();
                        }
                      }),
                      labelStyle: labelStyle,
                    ),
                    SizedBox(
                      width: 240,
                      child: _VercelInput(
                        label: '開刀日期',
                        controller: _surgeryDateController,
                        readOnly: true,
                        enabled: _hadSurgery == true,
                        onTap: _hadSurgery == true
                            ? _pickSurgeryDate
                            : null,
                        placeholder: _hadSurgery == true
                            ? '未指定'
                            : '（需先設定為「是」）',
                        labelStyle: labelStyle,
                        suffixIcon: _DateSuffixIcon(
                          hasValue: _surgeryDate != null,
                          enabled: _hadSurgery == true,
                          onClear: () => setState(() {
                            _surgeryDate = null;
                            _updateSurgeryDateDisplay();
                          }),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: _VercelInput(
                        label: '開刀類型',
                        controller: _surgeryTypeController,
                        enabled: _hadSurgery == true,
                        labelStyle: labelStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: colors.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  '復健治療',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TriBoolField(
                      label: 'PT',
                      value: _pt,
                      onChanged: (v) => setState(() => _pt = v),
                      labelStyle: labelStyle,
                      width: 140,
                    ),
                    _TriBoolField(
                      label: 'OT',
                      value: _ot,
                      onChanged: (v) => setState(() => _ot = v),
                      labelStyle: labelStyle,
                      width: 140,
                    ),
                    _TriBoolField(
                      label: 'ST',
                      value: _st,
                      onChanged: (v) => setState(() => _st = v),
                      labelStyle: labelStyle,
                      width: 140,
                    ),
                    SizedBox(
                      width: 320,
                      child: _VercelInput(
                        label: '自費項目',
                        controller: _selfPayItemsController,
                        labelStyle: labelStyle,
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: _VercelInput(
                        label: '其它項目',
                        controller: _otherItemsController,
                        labelStyle: labelStyle,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _resetMedicalHistorySection,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.onSurfaceVariant,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('清空此區塊'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: '生活習慣',
              subtitle: '抽菸喝酒、運動與健康檢查（可不填）',
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TriBoolField(
                      label: '定期健康檢查',
                      value: _regularHealthCheck,
                      onChanged: (v) =>
                          setState(() => _regularHealthCheck = v),
                      labelStyle: labelStyle,
                    ),
                    _TriBoolField(
                      label: '定期牙科檢查',
                      value: _regularDentalCheck,
                      onChanged: (v) =>
                          setState(() => _regularDentalCheck = v),
                      labelStyle: labelStyle,
                    ),
                    _TriBoolField(
                      label: '抽菸',
                      value: _smoking,
                      onChanged: (v) => setState(() => _smoking = v),
                      labelStyle: labelStyle,
                      width: 140,
                    ),
                    _TriBoolField(
                      label: '喝酒',
                      value: _drinking,
                      onChanged: (v) => setState(() {
                        _drinking = v;
                        if (v != true) {
                          _drinkingFrequencyController.clear();
                          _drinkingAmountController.clear();
                        }
                      }),
                      labelStyle: labelStyle,
                      width: 140,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VercelInput(
                        label: '喝酒頻率',
                        controller: _drinkingFrequencyController,
                        enabled: _drinking == true,
                        placeholder: _drinking == true
                            ? '例如：每週 1 次'
                            : '（需先設定喝酒為「是」）',
                        labelStyle: labelStyle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: '喝酒量',
                        controller: _drinkingAmountController,
                        enabled: _drinking == true,
                        placeholder: _drinking == true
                            ? '例如：啤酒 1 杯'
                            : '（需先設定喝酒為「是」）',
                        labelStyle: labelStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _VercelInput(
                  label: '運動習慣（簡述）',
                  controller: _exerciseHabitController,
                  labelStyle: labelStyle,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _ChipsEditor(
                  label: '運動類型',
                  labelStyle: labelStyle,
                  hintText: '例如：走路、游泳、瑜珈…',
                  items: _exerciseTypes,
                  onChanged: (next) =>
                      setState(() => _exerciseTypes = next),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TriBoolField(
                      label: '費力運動 ≥10 分鐘',
                      value: _vigorous10min,
                      onChanged: (v) => setState(() {
                        _vigorous10min = v;
                        if (v != true) {
                          _vigorous60minPerWeek = null;
                        }
                      }),
                      labelStyle: labelStyle,
                    ),
                    _TriBoolField(
                      label: '每週累積 ≥60 分鐘',
                      value: _vigorous60minPerWeek,
                      enabled: _vigorous10min == true,
                      onChanged: (v) =>
                          setState(() => _vigorous60minPerWeek = v),
                      labelStyle: labelStyle,
                    ),
                    _TriBoolField(
                      label: '中等費力 ≥10 分鐘',
                      value: _moderate10min,
                      onChanged: (v) => setState(() {
                        _moderate10min = v;
                        if (v != true) {
                          _moderateDaysPerWeekController.clear();
                          _moderateMinutesPerDayController.clear();
                        }
                      }),
                      labelStyle: labelStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VercelInput(
                        label: '中等費力每週天數 (0-7)',
                        controller: _moderateDaysPerWeekController,
                        enabled: _moderate10min == true,
                        keyboardType: TextInputType.number,
                        labelStyle: labelStyle,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = int.tryParse(raw);
                          if (parsed == null) return '整數';
                          if (parsed < 0 || parsed > 7) return '0~7';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _VercelInput(
                        label: '中等費力每日分鐘',
                        controller: _moderateMinutesPerDayController,
                        enabled: _moderate10min == true,
                        keyboardType: TextInputType.number,
                        labelStyle: labelStyle,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final parsed = int.tryParse(raw);
                          if (parsed == null) return '整數';
                          if (parsed < 0) return '不可為負';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetLifestyleSection,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('清空此區塊'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.navigator.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: Text(_isEdit ? '儲存變更' : '建立使用者'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

/// 仿 Vercel 風格的輸入框元件：標籤在上方，輸入框簡潔。
class _VercelInput extends StatelessWidget {
  const _VercelInput({
    required this.label,
    required this.controller,
    required this.labelStyle,
    this.placeholder,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final TextStyle labelStyle;
  final String? placeholder;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: colors.onSurface, fontSize: 14),
          cursorColor: colors.primary,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF111111) : colors.surface,
            hoverColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.fromBorderSide(
          BorderSide(color: colors.outlineVariant),
        ),
      ),
        child: Theme(
          data: context.theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
          iconColor: colors.onSurfaceVariant,
          collapsedIconColor: colors.onSurfaceVariant,
          children: children,
        ),
      ),
    );
  }
}

class _TriBoolField extends StatelessWidget {
  const _TriBoolField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.labelStyle,
    this.width = 200,
    this.enabled = true,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final TextStyle labelStyle;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final current = value == null
        ? _TriBoolValue.unset
        : (value! ? _TriBoolValue.yes : _TriBoolValue.no);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 8),
          // 統一使用共用下拉組件，避免 DropdownButtonFormField 在淺色模式出現
          // 「字太淡 / 選取藍底」等不符合 dashboard 風格的預設行為。
          AppSelect<_TriBoolValue>(
            value: current,
            items: const [
              _TriBoolValue.unset,
              _TriBoolValue.yes,
              _TriBoolValue.no,
            ],
            enabled: enabled,
            itemLabelBuilder: (item) {
              switch (item) {
                case _TriBoolValue.unset:
                  return '未設定';
                case _TriBoolValue.yes:
                  return '是';
                case _TriBoolValue.no:
                  return '否';
              }
            },
            onChanged: enabled
                ? (next) {
                    switch (next) {
                      case _TriBoolValue.unset:
                        onChanged(null);
                        break;
                      case _TriBoolValue.yes:
                        onChanged(true);
                        break;
                      case _TriBoolValue.no:
                        onChanged(false);
                        break;
                    }
                  }
                : null,
            menuWidth: const BoxConstraints(minWidth: 140, maxWidth: 220),
          ),
        ],
      ),
    );
  }
}

enum _TriBoolValue { unset, yes, no }

class _ChipsEditor extends StatefulWidget {
  const _ChipsEditor({
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final String label;
  final TextStyle labelStyle;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String? hintText;

  @override
  State<_ChipsEditor> createState() => _ChipsEditorState();
}

class _ChipsEditorState extends State<_ChipsEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addFromInput() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      return;
    }
    final parts = raw
        .split(RegExp(r'[,、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    final next = [...widget.items];
    for (final part in parts) {
      if (next.contains(part)) {
        continue;
      }
      next.add(part);
    }
    widget.onChanged(next);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: widget.labelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in widget.items)
              InputChip(
                label: Text(item),
                labelStyle: TextStyle(color: colors.onSurface, fontSize: 13),
                onDeleted: () {
                  widget.onChanged(
                    widget.items
                        .where((e) => e != item)
                        .toList(growable: false),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: colors.onSurface, fontSize: 14),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF111111) : colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
                onSubmitted: (_) => _addFromInput(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _addFromInput,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('加入'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateSuffixIcon extends StatelessWidget {
  const _DateSuffixIcon({
    required this.hasValue,
    required this.onClear,
    this.enabled = true,
  });

  final bool hasValue;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasValue)
          AppTooltip(
            message: '清除日期',
            child: IconButton(
              onPressed: enabled ? onClear : null,
              icon: Icon(Icons.close, size: 16, color: colors.onSurfaceVariant),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        const SizedBox(width: 4),
        Icon(
          Icons.calendar_today,
          size: 16,
          color: enabled ? colors.onSurfaceVariant : colors.outlineVariant,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
