import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/providers/platform_env_provider.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/apk/data/apk_repository.dart';
import 'package:gait_charts/features/apk/domain/models/apk_artifact_platform.dart';
import 'package:gait_charts/features/apk/domain/models/apk_file.dart';
import 'package:gait_charts/features/apk/domain/models/apk_file_list.dart';
import 'package:gait_charts/features/apk/domain/utils/apk_artifact_classifier.dart';

/// 統一的 requestId：用於 failure-gate 與 AsyncRequestView。
const String kApkListRequestId = 'apk_files';

/// 取得 `/apk` 檔案清單。
///
/// - 透過 `fetchWithFailureGate` 避免在相同 baseUrl 下連續失敗造成 error-loop。
final apkFileListProvider = FutureProvider<ApkFileListResponse>((ref) async {
  final repo = ref.watch(apkRepositoryProvider);
  final config = ref.watch(appConfigProvider);
  final fingerprint = Object.hashAll([config.baseUrl]);

  return fetchWithFailureGate(
    ref,
    requestId: kApkListRequestId,
    fingerprint: fingerprint,
    fetch: repo.listFiles,
  );
});

/// 是否顯示「所有平台」的下載檔（預設：Web 顯示全部；非 Web 只顯示目前平台）。
///
/// Riverpod 3：用 Notifier 承載可變狀態（避免引入舊式 StateProvider pattern）。
class ApkDownloadsShowAllPlatformsNotifier extends Notifier<bool> {
  @override
  bool build() {
    final env = ref.watch(platformEnvProvider);
    return env.isWeb;
  }

  void set(bool value) => state = value;

  void toggle() => state = !state;
}

final apkDownloadsShowAllPlatformsProvider =
    NotifierProvider<ApkDownloadsShowAllPlatformsNotifier, bool>(
  ApkDownloadsShowAllPlatformsNotifier.new,
);

/// 下載頁/卡片的「已排序且依平台分組」資料。
///
/// - 避免在 widget `build()` 裡做排序/分類
/// - 讓 UI 只負責渲染
final apkDownloadsGroupedFilesProvider =
    Provider<AsyncValue<Map<ApkArtifactPlatform, List<ApkFile>>>>((ref) {
  final env = ref.watch(platformEnvProvider);
  final showAll = ref.watch(apkDownloadsShowAllPlatformsProvider);
  final async = ref.watch(apkFileListProvider);

  return async.whenData((data) {
    final files = [...data.files]
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    ApkArtifactPlatform currentPlatform() {
      switch (env.targetPlatform) {
        case TargetPlatform.android:
          return ApkArtifactPlatform.android;
        case TargetPlatform.windows:
          return ApkArtifactPlatform.windows;
        case TargetPlatform.macOS:
          return ApkArtifactPlatform.macos;
        case TargetPlatform.linux:
          return ApkArtifactPlatform.linux;
        case TargetPlatform.iOS:
          // iOS 沒有提供安裝包；先以 unknown 表示（UI 會 fallback）。
          return ApkArtifactPlatform.unknown;
        case TargetPlatform.fuchsia:
          return ApkArtifactPlatform.unknown;
      }
    }

    final grouped = <ApkArtifactPlatform, List<ApkFile>>{};
    for (final f in files) {
      final p = classifyApkArtifactPlatform(f.name);
      (grouped[p] ??= <ApkFile>[]).add(f);
    }

    if (showAll) return grouped;

    final wanted = currentPlatform();
    final only = <ApkArtifactPlatform, List<ApkFile>>{};
    final list = grouped[wanted];
    if (list != null && list.isNotEmpty) {
      only[wanted] = list;
      return only;
    }

    // fallback：若目前平台沒有對應檔案，回傳所有檔案（避免畫面空白）。
    return grouped;
  });
});

/// 永遠回傳「全部平台」分組（忽略 UI toggle）。
///
/// 用於：完整下載頁 / Dialog（避免使用者看不到其他平台的產物）。
final apkDownloadsGroupedFilesAllPlatformsProvider =
    Provider<AsyncValue<Map<ApkArtifactPlatform, List<ApkFile>>>>((ref) {
  final async = ref.watch(apkFileListProvider);
  return async.whenData((data) {
    final files = [...data.files]
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    final grouped = <ApkArtifactPlatform, List<ApkFile>>{};
    for (final f in files) {
      final p = classifyApkArtifactPlatform(f.name);
      (grouped[p] ??= <ApkFile>[]).add(f);
    }
    return grouped;
  });
});


