import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/apk/data/services/apk_api_service.dart';
import 'package:gait_charts/features/apk/domain/models/apk_file_list.dart';

/// APK feature 的 repository：只做 delegate + 輕量轉換。
class ApkRepository {
  ApkRepository({required ApkApiService api}) : _api = api;

  final ApkApiService _api;

  Future<ApkFileListResponse> listFiles() => _api.listFiles();
}

final apkRepositoryProvider = Provider<ApkRepository>((ref) {
  return ApkRepository(api: ref.watch(apkApiServiceProvider));
});


