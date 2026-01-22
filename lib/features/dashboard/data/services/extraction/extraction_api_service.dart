import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 影像姿態擷取相關 API
class ExtractionApiService {
  ExtractionApiService(this._dio);

  final Dio _dio;

  /// Realsense Pose Extractor 相關 API 的 base endpoint。
  static const _kRealsensePoseExtractorEndpoint = '/realsense-pose-extractor';

  /// 觸發姿態擷取（建立背景 job，`POST /realsense-pose-extractor/extract`）。
  static const _extractEndpoint = '$_kRealsensePoseExtractorEndpoint/extract';

  /// 查詢姿態擷取 job 狀態（`GET /realsense-pose-extractor/extract/jobs/{job_id}`）。
  static const _extractJobEndpoint =
      '$_kRealsensePoseExtractorEndpoint/extract/jobs';

  Future<ExtractResult> triggerExtraction({
    String? bagId,
    String? bagPath,
    String? sessionName,
    String? userCode,
    ExtractConfig? config,
  }) async {
    try {
      final normalizedId = bagId?.trim();
      final normalizedPath = bagPath?.trim();

      final hasId = normalizedId != null && normalizedId.isNotEmpty;
      final hasPath = normalizedPath != null && normalizedPath.isNotEmpty;
      if (hasId == hasPath) {
        // 兩者都提供或兩者都沒提供都算錯
        throw ApiException(message: '請提供 bag_id 或 bag_path（且只能擇一）。');
      }

      // 新版後端預設 background=true（避免長任務造成連線 timeout）。
      // 這裡也明確帶上 background=true，確保行為一致。
      final response = await withApiRetry(
        () => _dio.post<dynamic>(
          _extractEndpoint,
          queryParameters: <String, dynamic>{
            if (hasId) 'bag_id': normalizedId,
            if (hasPath) 'bag_path': normalizedPath,
            if (sessionName != null && sessionName.isNotEmpty)
              'session_name': sessionName,
            if (userCode != null && userCode.trim().isNotEmpty)
              'user_code': userCode.trim(),
            'background': true,
          },
          data: (config ?? const ExtractConfig()).toJson(),
          options: Options(
            // background job 建立應該很快；用較短 timeout，避免卡住 UI。
            sendTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ),
      );

      // 200：同步完成；202：已建立 job（需輪詢 status）
      final statusCode = response.statusCode ?? 200;
      final data = response.data;
      if (data is! Map) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      final body = Map<String, dynamic>.from(data);

      if (statusCode == 202) {
        final created = ExtractJobCreatedResponse.fromJson(body);
        if (created.jobId.trim().isEmpty) {
          throw ApiException(message: '建立提取任務失敗：缺少 job_id。');
        }
        return await _pollExtractJob(created.jobId);
      }

      return ExtractResult.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<ExtractResult> _pollExtractJob(String jobId) async {
    // 以漸進式間隔輪詢，避免過度打爆後端。
    const baseDelay = Duration(milliseconds: 900);
    const maxDelay = Duration(seconds: 5);
    const maxWait = Duration(minutes: 40);

    final startedAt = DateTime.now();
    var attempt = 0;

    while (true) {
      if (DateTime.now().difference(startedAt) > maxWait) {
        throw ApiException(message: '提取任務等待逾時，請稍後再試或查看伺服器狀態。');
      }

      ExtractJobStatusResponse status;
      try {
        final resp = await withApiRetry(
          () => _dio.get<Map<String, dynamic>>(
            '$_extractJobEndpoint/$jobId',
            options: Options(
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
            ),
          ),
        );
        final body = resp.data;
        if (body == null) {
          throw ApiException(message: '伺服器未回傳有效的 job 狀態。');
        }
        status = ExtractJobStatusResponse.fromJson(body);
      } on DioException catch (error) {
        throw mapDioError(error);
      }

      final s = status.status.toLowerCase().trim();
      if (s == 'succeeded') {
        final result = status.result;
        if (result == null || result.success != true) {
          throw ApiException(message: '提取任務已完成，但回傳結果不完整。');
        }
        return result;
      }
      if (s == 'failed') {
        throw ApiException(message: status.error ?? '提取任務失敗。');
      }

      // pending / running：等待後再查一次
      attempt++;
      final nextDelay = Duration(
        milliseconds: (baseDelay.inMilliseconds + attempt * 250)
            .clamp(baseDelay.inMilliseconds, maxDelay.inMilliseconds),
      );
      await Future<void>.delayed(nextDelay);
    }
  }
}

final extractionApiServiceProvider = Provider<ExtractionApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ExtractionApiService(dio);
});
