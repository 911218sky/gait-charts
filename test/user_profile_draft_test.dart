import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

void main() {
  group('UserProfileDraft.toPatchJson', () {
    test('沒有變更時應回傳空 patch', () {
      final original = UserItem(
        userCode: 'U-001',
        name: 'Alice',
        assessmentDate: DateTime(2025, 12, 16),
        sex: 'F',
        ageYears: 30,
        heightCm: 160,
        weightKg: 55,
        bmi: 21.5,
        educationLevel: 'College',
        notes: 'hello',
        createdAt: DateTime(2025, 12, 1, 10),
        updatedAt: DateTime(2025, 12, 1, 10),
      );

      final draft = UserProfileDraft(
        name: 'Alice',
        assessmentDate: DateTime(2025, 12, 16),
        sex: 'F',
        ageYears: 30,
        heightCm: 160,
        weightKg: 55,
        bmi: 21.5,
        educationLevel: 'College',
        notes: 'hello',
      );

      final patch = draft.toPatchJson(original: original);
      expect(patch, isEmpty);
    });

    test('變更文字欄位時應包含對應 key', () {
      final original = UserItem(
        userCode: 'U-001',
        name: 'Alice',
        createdAt: DateTime(2025, 12, 1, 10),
        updatedAt: DateTime(2025, 12, 1, 10),
        notes: 'hello',
      );

      const draft = UserProfileDraft(name: 'Alice', notes: 'updated');
      final patch = draft.toPatchJson(original: original);

      expect(patch, containsPair('notes', 'updated'));
    });

    test('清空文字欄位時應輸出 null 以便後端清除', () {
      final original = UserItem(
        userCode: 'U-001',
        name: 'Alice',
        createdAt: DateTime(2025, 12, 1, 10),
        updatedAt: DateTime(2025, 12, 1, 10),
        notes: 'hello',
      );

      const draft = UserProfileDraft(name: 'Alice', notes: '');
      final patch = draft.toPatchJson(original: original);

      expect(patch.containsKey('notes'), isTrue);
      expect(patch['notes'], isNull);
    });
  });
}
