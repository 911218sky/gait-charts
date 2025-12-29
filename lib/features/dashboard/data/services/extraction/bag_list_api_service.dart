import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';

/// 伺服器 bag 清單 API
class BagListApiService {
  BagListApiService(this._dio);

  final Dio _dio;

  /// Realsense Pose Extractor 相關 API 的 base endpoint。
  static const _kRealsensePoseExtractorEndpoint = '/realsense_pose_extractor';

  /// 列出伺服器上的 .bag 檔案清單（`GET /realsense_pose_extractor/bags`）。
  static const _bagsEndpoint = '$_kRealsensePoseExtractorEndpoint/bags';

  Future<BagFileListResponse> fetchServerBags({
    int page = 1,
    int pageSize = 50,
    bool recursive = true,
    String? query,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.get<Map<String, dynamic>>(
          _bagsEndpoint,
          queryParameters: <String, dynamic>{
            'page': page,
            'page_size': pageSize,
            'recursive': recursive,
            if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
          },
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return BagFileListResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

final bagListApiServiceProvider = Provider<BagListApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return BagListApiService(dio);
});


