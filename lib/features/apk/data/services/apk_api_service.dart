import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/apk/domain/models/apk_file_list.dart';

/// APK 檔案清單 / 下載 API。
class ApkApiService {
  ApkApiService(this._dio);

  final Dio _dio;

  static const _apkEndpoint = '/apk';

  Future<ApkFileListResponse> listFiles() async {
    try {
      final response = await withApiRetry(
        () => _dio.get<Map<String, dynamic>>(_apkEndpoint),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return ApkFileListResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

final apkApiServiceProvider = Provider<ApkApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApkApiService(dio);
});


