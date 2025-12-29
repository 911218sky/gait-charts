import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/core/platform/platform_env.dart';
import 'package:gait_charts/features/dashboard/domain/feature_availability.dart';

void main() {
  group('DashboardFeatureAvailability.blockedMessage', () {
    const availability = DashboardFeatureAvailability();

    test('Web 上資料提取不應被擋下', () {
      const env = PlatformEnv(isWeb: true, targetPlatform: TargetPlatform.macOS);
      final message = availability.blockedMessage(
        feature: DashboardFeature.extraction,
        env: env,
      );

      expect(message, isNull);
    });

    test('手機版資料提取不應被擋下', () {
      const env = PlatformEnv(isWeb: false, targetPlatform: TargetPlatform.android);
      final message = availability.blockedMessage(
        feature: DashboardFeature.extraction,
        env: env,
      );

      expect(message, isNull);
    });

    test('桌面版資料提取不應被擋下', () {
      const env = PlatformEnv(isWeb: false, targetPlatform: TargetPlatform.windows);
      final message = availability.blockedMessage(
        feature: DashboardFeature.extraction,
        env: env,
      );

      expect(message, isNull);
    });

    test('Web 上本機檔案選取應被擋下', () {
      const env = PlatformEnv(isWeb: true, targetPlatform: TargetPlatform.macOS);
      final message = availability.blockedMessage(
        feature: DashboardFeature.extractionLocalBag,
        env: env,
      );

      expect(message, isNotNull);
      expect(message, contains('網頁版'));
    });

    test('手機版本機檔案選取應被擋下', () {
      const env = PlatformEnv(isWeb: false, targetPlatform: TargetPlatform.android);
      final message = availability.blockedMessage(
        feature: DashboardFeature.extractionLocalBag,
        env: env,
      );

      expect(message, isNotNull);
      expect(message, contains('手機版'));
    });

    test('桌面版本機檔案選取不應被擋下', () {
      const env = PlatformEnv(isWeb: false, targetPlatform: TargetPlatform.windows);
      final message = availability.blockedMessage(
        feature: DashboardFeature.extractionLocalBag,
        env: env,
      );

      expect(message, isNull);
    });
  });
}


