import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/user_info_components.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:intl/intl.dart';

/// 影片播放頁面旁邊顯示的使用者資訊面板內容。
class VideoUserInfoCard extends StatelessWidget {
  const VideoUserInfoCard({
    required this.user,
    this.sessions = const [],
    this.currentSessionName,
    this.onSessionTap,
    super.key,
  });

  final UserItem user;
  final List<UserSessionItem> sessions;
  final String? currentSessionName;
  final void Function(String sessionName)? onSessionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        Divider(height: 1, color: colors.outlineVariant),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sessions.isNotEmpty) ...[
                  _buildSessionsList(context),
                  const SizedBox(height: 32),
                ],
                _buildBasicInfo(context),
                const SizedBox(height: 32),
                _buildPhysicalInfo(context),
                const SizedBox(height: 32),
                _buildDiagnosisInfo(context),
                const SizedBox(height: 32),
                _buildNotesSection(context),
                const SizedBox(height: 32),
                _buildMapSection(
                  context,
                  title: '病史',
                  data: user.medicalHistory ?? {},
                ),
                const SizedBox(height: 32),
                _buildMapSection(
                  context,
                  title: '症狀',
                  data: user.symptoms ?? {},
                ),
                const SizedBox(height: 32),
                _buildMapSection(
                  context,
                  title: '生活型態',
                  data: user.lifestyle ?? {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatarCircle(name: user.name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.userCode,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InfoStatsRow(
            items: [
              InfoStatItem(label: '總記錄', value: '${sessions.length}'),
              InfoStatItem(
                label: '最近評估',
                value: user.assessmentDate != null
                    ? DateFormat('MM/dd').format(user.assessmentDate!)
                    : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoSectionTitle(title: 'Sessions'),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          separatorBuilder: (context, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final session = sessions[index];
            final isSelected = session.sessionName == currentSessionName;
            final hasVideo = session.hasVideo;
            
            return SessionListItem(
              sessionName: session.sessionName,
              createdAt: session.createdAt,
              hasVideo: hasVideo,
              isSelected: isSelected,
              isDisabled: isSelected || !hasVideo,
              onTap: (isSelected || !hasVideo)
                  ? null
                  : () => onSessionTap?.call(session.sessionName),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoSectionTitle(title: '基本資料'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            InfoLabelValue(
              label: '族群',
              value: user.cohort.isNotEmpty ? user.cohort.join('、') : '未填寫',
              width: 220,
              maxLines: 2,
            ),
            InfoLabelValue(
              label: '年齡',
              value: user.ageYears != null ? '${user.ageYears} 歲' : '未填寫',
              width: 140,
            ),
            InfoLabelValue(
              label: '性別',
              value: _formatSex(user.sex),
              width: 140,
            ),
            InfoLabelValue(
              label: '收案日期',
              value: user.assessmentDate != null
                  ? DateFormat('yyyy/MM/dd').format(user.assessmentDate!)
                  : '未填寫',
              width: 140,
            ),
            InfoLabelValue(
              label: '教育程度',
              value: (user.educationLevel?.isNotEmpty ?? false)
                  ? user.educationLevel!
                  : '未填寫',
              width: 140,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhysicalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoSectionTitle(title: '身體數據'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InfoMetricCard(
                label: '身高',
                value: user.heightCm?.toStringAsFixed(1) ?? '-',
                unit: user.heightCm != null ? 'cm' : '',
                badge: user.heightCm == null ? '未填寫' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoMetricCard(
                label: '體重',
                value: user.weightKg?.toStringAsFixed(1) ?? '-',
                unit: user.weightKg != null ? 'kg' : '',
                badge: user.weightKg == null ? '未填寫' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InfoMetricCard(
          label: 'BMI',
          value: user.bmi?.toStringAsFixed(1) ?? '-',
          badge: user.bmi != null ? _getBmiCategory(user.bmi!) : '未填寫',
        ),
      ],
    );
  }

  Widget _buildDiagnosisInfo(BuildContext context) {
    final colors = context.colorScheme;
    final diagnosis = user.diagnosis ?? {};
    final mainDiagnosis = diagnosis['main_diagnosis']?.toString();
    final subtype = diagnosis['subtype']?.toString();

    final isEmpty = (mainDiagnosis == null || mainDiagnosis.isEmpty) &&
        (subtype == null || subtype.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoSectionTitle(title: '診斷資訊'),
        const SizedBox(height: 12),
        InfoSectionContainer(
          child: isEmpty
              ? Text(
                  '未填寫',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoLabelValue(
                      label: '主診斷',
                      value: (mainDiagnosis?.isNotEmpty ?? false)
                          ? mainDiagnosis!
                          : '未填寫',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    InfoLabelValue(
                      label: '亞型',
                      value:
                          (subtype?.isNotEmpty ?? false) ? subtype! : '未填寫',
                      maxLines: 3,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final hasNotes = user.notes != null && user.notes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoSectionTitle(title: '備註'),
        const SizedBox(height: 12),
        InfoSectionContainer(
          child: Text(
            hasNotes ? user.notes! : '未填寫',
            style: textTheme.bodyMedium?.copyWith(
              color: hasNotes
                  ? colors.onSurface.withValues(alpha: 0.8)
                  : colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(
    BuildContext context, {
    required String title,
    required Map<String, Object?> data,
  }) {
    final colors = context.colorScheme;
    final filteredEntries = data.entries.toList();
    final isEmpty = filteredEntries.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoSectionTitle(title: title),
        const SizedBox(height: 12),
        InfoSectionContainer(
          child: isEmpty
              ? Text(
                  '未填寫',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < filteredEntries.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildMapEntry(context, filteredEntries[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMapEntry(BuildContext context, MapEntry<String, Object?> entry) {
    final colors = context.colorScheme;
    final label = _formatFieldLabel(entry.key);
    final value = entry.value;

    // 如果值是 Map，需要特殊處理（顯示為多行）
    if (value is Map && value.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...value.entries.map((e) {
            final subLabel = _formatFieldLabel(e.key.toString());
            final subValue = _formatSingleValue(e.value);
            final displayValue = subValue.isEmpty ? '未填寫' : subValue;
            
            return Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      subLabel,
                      style: TextStyle(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        color: displayValue == '未填寫'
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    // 一般值使用 InfoLabelValue
    final displayValue = _formatMapValue(value);
    return InfoLabelValue(
      label: label,
      value: displayValue,
      maxLines: 5,
    );
  }

  String _formatMapValue(Object? value) {
    if (value == null) return '未填寫';

    if (value is String && value.trim().isEmpty) return '未填寫';
    
    // 處理布林值
    if (value is bool) {
      return value ? '是' : '否';
    }
    
    // 處理字串形式的布林值
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true') return '是';
      if (lower == 'false') return '否';
    }

    if (value is List) {
      if (value.isEmpty) return '未填寫';
      final items = value
          .map(_formatSingleValue)
          .where((s) => s.isNotEmpty)
          .join('、');
      return items.isEmpty ? '未填寫' : items;
    }

    if (value is Map) {
      if (value.isEmpty) return '未填寫';
      
      // 將 Map 轉換為多行顯示，每個項目一行
      final items = value.entries
          .where((e) => e.value != null)
          .map((e) {
            final label = _formatFieldLabel(e.key.toString());
            final val = _formatSingleValue(e.value);
            // 如果值為空，顯示「未填寫」
            final displayValue = val.isEmpty ? '未填寫' : val;
            return '$label：$displayValue';
          })
          .toList();
      
      return items.isEmpty ? '未填寫' : items.join('\n');
    }

    return value.toString();
  }

  String _formatSingleValue(Object? value) {
    if (value == null) return '';
    
    if (value is bool) {
      return value ? '是' : '否';
    }
    
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return '';
      
      final lower = trimmed.toLowerCase();
      if (lower == 'true') return '是';
      if (lower == 'false') return '否';
      
      return trimmed;
    }
    
    return value.toString();
  }

  String _formatFieldLabel(String key) {
    const labelMap = {
      // 診斷相關
      'main_diagnosis': '主診斷',
      'subtype': '亞型',
      'onset_date': '發病日期',
      'duration': '病程',
      'severity': '嚴重程度',
      
      // 病史相關
      'relevant_exams': '相關檢查',
      'exam_notes': '檢查備註',
      'other_diseases': '其他疾病',
      'surgery': '手術史',
      'surgery_date': '手術日期',
      'surgery_type': '手術類型',
      'had_surgery': '曾接受手術',
      'rehab_treatment': '復健治療',
      'pt': '物理治療',
      'ot': '職能治療',
      'st': '語言治療',
      'self_pay_items': '自費項目',
      'other_items': '其他項目',
      'medications': '用藥',
      'medication_adherence': '用藥遵從性',
      'allergies': '過敏史',
      'surgeries': '手術史',
      'family_history': '家族史',
      'chronic_diseases': '慢性病',
      
      // 症狀相關
      'symptoms': '症狀',
      'pain_level': '疼痛程度',
      'pain_score': '疼痛評分',
      'pain_location': '疼痛位置',
      'pain_side': '疼痛側邊',
      'fall_count': '跌倒次數',
      'last_fall_date': '最近跌倒日期',
      'mobility': '行動能力',
      'balance': '平衡能力',
      'fatigue': '疲勞程度',
      'sleep_quality': '睡眠品質',
      
      // 生活型態相關
      'regular_health_check': '定期健康檢查',
      'regular_dental_check': '定期牙科檢查',
      'smoking': '吸菸',
      'drinking': '飲酒',
      'drinking_frequency': '飲酒頻率',
      'drinking_amount': '飲酒量',
      'exercise_habit': '運動習慣',
      'exercise_types': '運動類型',
      'vigorous_10min': '劇烈運動 10 分鐘',
      'vigorous_60min_per_week': '劇烈運動 60 分鐘/週',
      'moderate_10min': '中度運動 10 分鐘',
      'moderate_days_per_week': '中度運動天數/週',
      'moderate_minutes_per_day': '中度運動分鐘數/天',
      'exercise_frequency': '運動頻率',
      'exercise_type': '運動類型',
      'alcohol': '飲酒',
      'diet': '飲食習慣',
      'occupation': '職業',
      'living_situation': '居住狀況',
      'assistive_devices': '輔具使用',
    };

    if (labelMap.containsKey(key)) return labelMap[key]!;

    // 嘗試將常見的英文單字轉換為中文
    final lowerKey = key.toLowerCase();
    
    // 常見英文單字對照
    final wordMap = {
      'symptoms': '症狀',
      'pain': '疼痛',
      'side': '側邊',
      'score': '評分',
      'fall': '跌倒',
      'count': '次數',
      'last': '最近',
      'date': '日期',
      'type': '類型',
      'items': '項目',
      'self': '自費',
      'pay': '付費',
      'other': '其他',
      'surgery': '手術',
      'exam': '檢查',
      'exams': '檢查',
      'notes': '備註',
      'treatment': '治療',
      'medication': '用藥',
      'history': '史',
      'level': '程度',
      'location': '位置',
      'quality': '品質',
      'habit': '習慣',
      'frequency': '頻率',
      'amount': '量',
      'check': '檢查',
      'health': '健康',
      'dental': '牙科',
      'regular': '定期',
    };
    
    // 嘗試組合翻譯
    for (final entry in wordMap.entries) {
      if (lowerKey.contains(entry.key)) {
        // 如果包含這個單字，嘗試替換
        final translated = key
            .replaceAll(RegExp(entry.key, caseSensitive: false), entry.value)
            .replaceAll('_', ' ')
            .trim();
        if (translated != key) {
          return translated;
        }
      }
    }

    // 將 snake_case 轉為空格分隔的標題格式（保留原邏輯作為最後備案）
    return key
        .split('_')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  String _formatSex(String? sex) {
    if (sex == null || sex.isEmpty) return '未填寫';
    switch (sex.toLowerCase()) {
      case 'male':
      case 'm':
        return '男性';
      case 'female':
      case 'f':
        return '女性';
      default:
        return sex;
    }
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return '過輕';
    if (bmi < 24) return '正常';
    if (bmi < 27) return '過重';
    return '肥胖';
  }
}

/// 尚未選擇 Session 時顯示的提示。
class VideoUserNoSessionCard extends StatelessWidget {
  const VideoUserNoSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoEmptyState(
      icon: Icons.video_library_outlined,
      title: '請先選擇 Session',
      subtitle: '選擇 Session 後將顯示綁定的使用者資訊',
    );
  }
}

/// 未綁定使用者時顯示的空狀態。
class VideoUserEmptyCard extends StatelessWidget {
  const VideoUserEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoEmptyState(
      icon: Icons.person_off_outlined,
      title: '尚未綁定使用者',
      subtitle: '此 Session 尚未連結到任何個案資料',
    );
  }
}

/// 載入中狀態。
class VideoUserLoadingCard extends StatelessWidget {
  const VideoUserLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
