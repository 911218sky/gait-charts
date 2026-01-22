import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 顯示使用者的問卷/擴充欄位（診斷、症狀、醫療史、生活習慣）。
class UserProfileSectionsCard extends StatelessWidget {
  const UserProfileSectionsCard({required this.user, super.key});

  final UserItem user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final diagnosis = user.diagnosis ?? const <String, Object?>{};
    final symptoms = user.symptoms ?? const <String, Object?>{};
    final medicalHistory = user.medicalHistory ?? const <String, Object?>{};
    final lifestyle = user.lifestyle ?? const <String, Object?>{};

    final hasAny =
        _hasAnyValue(diagnosis) ||
        _hasAnyValue(symptoms) ||
        _hasAnyValue(medicalHistory) ||
        _hasAnyValue(lifestyle);

    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '問卷 / 健康資料',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                _CountChip(label: '診斷', count: _nonEmptyCount(diagnosis)),
                const SizedBox(width: 8),
                _CountChip(label: '症狀', count: _nonEmptyCount(symptoms)),
                const SizedBox(width: 8),
                _CountChip(label: '醫療史', count: _nonEmptyCount(medicalHistory)),
                const SizedBox(width: 8),
                _CountChip(label: '生活', count: _nonEmptyCount(lifestyle)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '這些欄位會跟著使用者一起保存，方便後續比對分析結果。',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (!hasAny)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.dividerColor),
                ),
                child: Text(
                  '尚未填寫問卷欄位（診斷 / 症狀 / 醫療史 / 生活習慣）。',
                  style: context.textTheme.bodyMedium,
                ),
              )
            else ...[
              _SectionTile(
                title: '診斷資訊',
                icon: Icons.healing_outlined,
                summary: _diagnosisSummary(diagnosis),
                initiallyExpanded: _hasAnyValue(diagnosis),
                child: _DiagnosisSection(map: diagnosis),
              ),
              const SizedBox(height: 12),
              _SectionTile(
                title: '症狀',
                icon: Icons.report_outlined,
                summary: _symptomsSummary(symptoms),
                initiallyExpanded: _hasAnyValue(symptoms),
                child: _SymptomsSection(map: symptoms),
              ),
              const SizedBox(height: 12),
              _SectionTile(
                title: '醫療史 / 用藥 / 復健',
                icon: Icons.medical_information_outlined,
                summary: _medicalHistorySummary(medicalHistory),
                initiallyExpanded: _hasAnyValue(medicalHistory),
                child: _MedicalHistorySection(map: medicalHistory),
              ),
              const SizedBox(height: 12),
              _SectionTile(
                title: '生活習慣',
                icon: Icons.local_florist_outlined,
                summary: _lifestyleSummary(lifestyle),
                initiallyExpanded: _hasAnyValue(lifestyle),
                child: _LifestyleSection(map: lifestyle),
              ),
            ],
          ],
        ),
      ),
    );

    return card;
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.dividerColor),
      ),
      child: Text(
        '$label：$count',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.title,
    required this.icon,
    required this.summary,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final String summary;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
      ),
      child: Theme(
        data: context.theme.copyWith(dividerColor: Colors.transparent),
        child: Builder(
          builder: (context) {
            final tile = ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Icon(
                icon,
                size: 18,
                color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              title: Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              iconColor: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              collapsedIconColor: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              children: [child],
            );

            return tile;
          },
        ),
      ),
    );
  }
}

class _DiagnosisSection extends StatelessWidget {
  const _DiagnosisSection({required this.map});

  final Map<String, Object?> map;

  @override
  Widget build(BuildContext context) {
    final items = <_KV>[
      _KV('診斷', _s(map['diagnosis'])),
      _KV('類型', _s(map['diagnosis_type'])),
      _KV('部位', _s(map['body_part'])),
      _KV('疾病/疫病', _s(map['disease'])),
      _KV('患側', _s(map['affected_side'])),
      _KV('發病日期', _s(map['onset_date'])),
      _KV('是否復發', _b(map['is_recurrent'])),
      _KV('是否失語症', _b(map['has_aphasia'])),
    ];
    return _KeyValueGrid(items: items);
  }
}

class _SymptomsSection extends StatelessWidget {
  const _SymptomsSection({required this.map});

  final Map<String, Object?> map;

  @override
  Widget build(BuildContext context) {
    final symptoms = _stringList(map['symptoms']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('目前困擾症狀'),
        const SizedBox(height: 8),
        if (symptoms.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final item in symptoms) Chip(label: Text(item))],
          )
        else
          const _EmptyValueText(),
        const SizedBox(height: 16),
        _KeyValueGrid(
          items: [
            _KV('疼痛部位', _s(map['pain_location'])),
            _KV('疼痛側別', _s(map['pain_side'])),
            _KV('疼痛分數', _n(map['pain_score'], suffix: ' /10')),
            _KV('跌倒次數', _n(map['fall_count'])),
            _KV('最近一次跌倒日期', _s(map['last_fall_date'])),
          ],
        ),
      ],
    );
  }
}

class _MedicalHistorySection extends StatelessWidget {
  const _MedicalHistorySection({required this.map});

  final Map<String, Object?> map;

  @override
  Widget build(BuildContext context) {
    final meds = _stringList(map['medications']);
    final surgery = _map(map['surgery']);
    final rehab = _map(map['rehab_treatment']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyValueGrid(
          items: [
            _KV('相關醫學檢查', _s(map['relevant_exams'])),
            _KV('檢查備註', _s(map['exam_notes'])),
            _KV('其它疾病史', _s(map['other_diseases'])),
            _KV('是否規律服藥', _b(map['medication_adherence'])),
            _KV('家族病史', _s(map['family_history'])),
          ],
        ),
        const SizedBox(height: 16),
        const _FieldLabel('目前服用藥物'),
        const SizedBox(height: 8),
        if (meds.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final item in meds) Chip(label: Text(item))],
          )
        else
          const _EmptyValueText(),
        const SizedBox(height: 16),
        const _FieldLabel('手術資訊'),
        const SizedBox(height: 8),
        _KeyValueGrid(
          items: [
            _KV('是否有開刀史', _b(surgery?['had_surgery'])),
            _KV('開刀日期', _s(surgery?['surgery_date'])),
            _KV('開刀類型', _s(surgery?['surgery_type'])),
          ],
        ),
        const SizedBox(height: 16),
        const _FieldLabel('復健治療'),
        const SizedBox(height: 8),
        _KeyValueGrid(
          items: [
            _KV('PT', _b(rehab?['pt'])),
            _KV('OT', _b(rehab?['ot'])),
            _KV('ST', _b(rehab?['st'])),
            _KV('自費項目', _s(rehab?['self_pay_items'])),
            _KV('其它項目', _s(rehab?['other_items'])),
          ],
        ),
      ],
    );
  }
}

class _LifestyleSection extends StatelessWidget {
  const _LifestyleSection({required this.map});

  final Map<String, Object?> map;

  @override
  Widget build(BuildContext context) {
    final exerciseTypes = _stringList(map['exercise_types']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyValueGrid(
          items: [
            _KV('定期健康檢查', _b(map['regular_health_check'])),
            _KV('定期牙科檢查', _b(map['regular_dental_check'])),
            _KV('抽菸', _b(map['smoking'])),
            _KV('喝酒', _b(map['drinking'])),
            _KV('喝酒頻率', _s(map['drinking_frequency'])),
            _KV('喝酒量', _s(map['drinking_amount'])),
            _KV('運動習慣', _s(map['exercise_habit'])),
            _KV('費力運動 ≥10 分鐘', _b(map['vigorous_10min'])),
            _KV('每週累積 ≥60 分鐘', _b(map['vigorous_60min_per_week'])),
            _KV('中等費力 ≥10 分鐘', _b(map['moderate_10min'])),
            _KV('中等費力每週天數', _n(map['moderate_days_per_week'])),
            _KV('中等費力每日分鐘', _n(map['moderate_minutes_per_day'])),
          ],
        ),
        const SizedBox(height: 16),
        const _FieldLabel('運動類型'),
        const SizedBox(height: 8),
        if (exerciseTypes.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in exerciseTypes) Chip(label: Text(item)),
            ],
          )
        else
          const _EmptyValueText(),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.items});

  final List<_KV> items;

  @override
  Widget build(BuildContext context) {
    final columns = context.isDesktopWide ? 2 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final kv in items)
              SizedBox(
                width: itemWidth,
                child: _KeyValueRow(label: kv.label, value: kv.value),
              ),
          ],
        );
      },
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue =
        value.trim().isEmpty || value == '—' ? '未填寫' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          displayValue,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyValueText extends StatelessWidget {
  const _EmptyValueText();

  @override
  Widget build(BuildContext context) {
    return Text(
      '未填寫',
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}

class _KV {
  const _KV(this.label, this.value);

  final String label;
  final String value;
}

String _s(Object? value) {
  final raw = value?.toString() ?? '';
  final trimmed = raw.trim();
  return trimmed.isEmpty ? '—' : trimmed;
}

String _b(Object? value) {
  if (value is bool) {
    return value ? '是' : '否';
  }
  if (value is String) {
    final lowered = value.trim().toLowerCase();
    if (lowered == 'true' || lowered == '1' || lowered == 'yes') {
      return '是';
    }
    if (lowered == 'false' || lowered == '0' || lowered == 'no') {
      return '否';
    }
  }
  return '—';
}

String _n(Object? value, {String suffix = ''}) {
  if (value is num) {
    return '${value.toString()}$suffix';
  }
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return '—';
  }
  return '$raw$suffix';
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((e) => e?.toString().trim())
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?>? _map(Object? value) {
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return null;
}

bool _hasAnyValue(Map<String, Object?> map) {
  for (final v in map.values) {
    if (v == null) continue;
    if (v is String && v.trim().isEmpty) continue;
    if (v is List && v.isEmpty) continue;
    if (v is Map && v.isEmpty) continue;
    return true;
  }
  return false;
}

int _nonEmptyCount(Map<String, Object?> map) {
  var count = 0;
  for (final v in map.values) {
    if (v == null) continue;
    if (v is String && v.trim().isEmpty) continue;
    if (v is List && v.isEmpty) continue;
    if (v is Map && v.isEmpty) continue;
    count++;
  }
  return count;
}

String _diagnosisSummary(Map<String, Object?> map) {
  final diagnosis = _s(map['diagnosis']);
  final side = _s(map['affected_side']);
  final onset = _s(map['onset_date']);
  final parts = <String>[];
  if (diagnosis != '—') parts.add(diagnosis);
  if (side != '—') parts.add('患側 $side');
  if (onset != '—') parts.add('發病 $onset');
  return parts.isEmpty ? '未填寫' : parts.join(' · ');
}

String _symptomsSummary(Map<String, Object?> map) {
  final score = _n(map['pain_score']);
  final falls = _n(map['fall_count']);
  final tags = _stringList(map['symptoms']);
  final parts = <String>[];
  if (tags.isNotEmpty) parts.add('${tags.length} 項困擾症狀');
  if (score != '—') parts.add('疼痛 $score');
  if (falls != '—') parts.add('跌倒 $falls');
  return parts.isEmpty ? '未填寫' : parts.join(' · ');
}

String _medicalHistorySummary(Map<String, Object?> map) {
  final meds = _stringList(map['medications']);
  final surgery = _map(map['surgery']);
  final hadSurgery = surgery == null ? '—' : _b(surgery['had_surgery']);
  final parts = <String>[];
  if (meds.isNotEmpty) parts.add('用藥 ${meds.length} 項');
  if (hadSurgery != '—') parts.add('開刀：$hadSurgery');
  return parts.isEmpty ? '未填寫' : parts.join(' · ');
}

String _lifestyleSummary(Map<String, Object?> map) {
  final smoking = _b(map['smoking']);
  final drinking = _b(map['drinking']);
  final types = _stringList(map['exercise_types']);
  final parts = <String>[];
  if (smoking != '—') parts.add('抽菸：$smoking');
  if (drinking != '—') parts.add('喝酒：$drinking');
  if (types.isNotEmpty) parts.add('運動 ${types.length} 類');
  return parts.isEmpty ? '未填寫' : parts.join(' · ');
}
