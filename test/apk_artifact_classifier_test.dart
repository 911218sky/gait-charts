import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/features/apk/domain/models/apk_artifact_platform.dart';
import 'package:gait_charts/features/apk/domain/utils/apk_artifact_classifier.dart';

void main() {
  group('classifyApkArtifactPlatform', () {
    test('android apks', () {
      expect(
        classifyApkArtifactPlatform('GaitCharts-arm64-v8a.apk'),
        ApkArtifactPlatform.android,
      );
      expect(
        classifyApkArtifactPlatform('GaitCharts-armeabi-v7a.apk'),
        ApkArtifactPlatform.android,
      );
      expect(
        classifyApkArtifactPlatform('GaitCharts-x86_64.apk'),
        ApkArtifactPlatform.android,
      );
    });

    test('linux artifacts', () {
      expect(
        classifyApkArtifactPlatform('GaitCharts-Linux-x64.tar.gz'),
        ApkArtifactPlatform.linux,
      );
      expect(
        classifyApkArtifactPlatform('GaitCharts-linux.tgz'),
        ApkArtifactPlatform.linux,
      );
    });

    test('macos artifacts', () {
      expect(
        classifyApkArtifactPlatform('GaitCharts-macOS.zip'),
        ApkArtifactPlatform.macos,
      );
      expect(
        classifyApkArtifactPlatform('GaitCharts.dmg'),
        ApkArtifactPlatform.macos,
      );
    });

    test('windows artifacts', () {
      expect(
        classifyApkArtifactPlatform('GaitCharts-Setup.exe'),
        ApkArtifactPlatform.windows,
      );
      expect(
        classifyApkArtifactPlatform('GaitCharts.msi'),
        ApkArtifactPlatform.windows,
      );
    });
  });
}


