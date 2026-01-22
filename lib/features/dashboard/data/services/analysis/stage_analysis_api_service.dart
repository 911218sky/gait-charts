import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/client/api_client.dart';
import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 步態分期 / Per-Lap 偏移分析相關 API 服務。
class StageAnalysisApiService {
  StageAnalysisApiService(this._dio);

  final Dio _dio;

  /// 復健分析（rehab analyzer）相關 API 的 base endpoint。
  static const _kRehabAnalyzerEndpoint = '/rehab-analyzer';

  /// 步態分期持續時間 - 分析各步態階段（支撐期、擺動期等）的時間分佈
  static const _stageDurationsEndpoint = '$_kRehabAnalyzerEndpoint/stage_durations';

  /// 每圈偏移分析 - 計算每圈行走時的空間偏移量
  static const _perLapOffsetEndpoint = '$_kRehabAnalyzerEndpoint/per_lap_offset';

  /// 每分鐘步頻與步長柱狀圖 - 統計每分鐘的步頻 (cadence) 與步長 (step length)
  static const _minutelyCadenceEndpoint =
      '$_kRehabAnalyzerEndpoint/minutely_cadence_step_length_bars';

  /// Y 軸高度差 - 分析左右對稱關節的垂直高度差異（用於評估步態對稱性）
  static const _yHeightDiffEndpoint = '$_kRehabAnalyzerEndpoint/y_height_diff';

  /// 空間頻譜 - 對 XZ/YZ 平面投影進行頻譜分析，找出週期性運動模式
  static const _spatialSpectrumEndpoint = '$_kRehabAnalyzerEndpoint/spatial_spectrum';

  /// 多關節 FFT - 對指定關節的時間序列進行 FFT 分析，輸出 PSD (Power Spectral Density)
  static const _multiFftEndpoint = '$_kRehabAnalyzerEndpoint/multi_fft_from_series';

  /// 每圈速度時空熱圖
  static const _speedHeatmapEndpoint = '$_kRehabAnalyzerEndpoint/speed_heatmap';

  /// 每分鐘左右擺動期（swing）百分比/秒數熱圖
  static const _swingInfoHeatmapEndpoint =
      '$_kRehabAnalyzerEndpoint/swing_info_heatmap';

  /// Top-down 軌跡動畫資料包（前端自行渲染）。
  static const _trajectoryPayloadEndpoint =
      '$_kRehabAnalyzerEndpoint/trajectory_payload';

  /// 步態週期相位分析。
  static const _gaitCyclePhasesEndpoint =
      '$_kRehabAnalyzerEndpoint/gait_cycle_phases';

  /// 每分鐘趨勢分析（速度與圈數）。
  static const _minutelyTrendEndpoint =
      '$_kRehabAnalyzerEndpoint/minutely_trend';

  /// 獲取步態分期持續時間分析結果。
  ///
  /// 此 API 會分析指定 session 的步態資料，計算各階段（如單腳支撐、雙腳支撐、
  /// 擺動期等）的持續時間統計。
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定（包含平滑窗口、閾值等）
  ///
  /// 回傳 [StageDurationsResponse]，包含各階段持續時間的統計資料。
  Future<StageDurationsResponse> fetchStageDurations({
    required String sessionName,
    required StageDurationsConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _stageDurationsEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return StageDurationsResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 獲取每圈偏移分析結果。
  ///
  /// 此 API 計算每圈行走時身體重心相對於理想軌跡的偏移量，
  /// 用於繪製偏移概覽圖、左右偏移對比圖、時間序列偏移圖等三個子圖。
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定（包含使用的關節點、平滑參數等）
  ///
  /// 回傳 [PerLapOffsetResponse]，包含每圈的偏移數據。
  Future<PerLapOffsetResponse> fetchPerLapOffset({
    required String sessionName,
    required PerLapOffsetConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _perLapOffsetEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return PerLapOffsetResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得每分鐘步頻與步長柱狀圖資料。
  ///
  /// 此 API 將整個 session 按分鐘切分，統計每分鐘的：
  /// - 步頻 (Cadence): 每分鐘步數
  /// - 步長 (Step Length): 平均每步距離
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定
  ///
  /// 回傳 [MinutelyCadenceStepLengthBarsResponse]，包含每分鐘的統計數據。
  Future<MinutelyCadenceStepLengthBarsResponse>
  fetchMinutelyCadenceStepLengthBars({
    required String sessionName,
    required MinutelyCadenceStepLengthBarsConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _minutelyCadenceEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return MinutelyCadenceStepLengthBarsResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得左右關節 Y 軸高度差序列。
  ///
  /// 此 API 計算左右對稱關節（如左右髖、左右膝、左右踝）在 Y 軸上的高度差異，
  /// 用於評估步態的垂直對稱性。正常步態應該左右對稱，高度差應接近零。
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定（包含要比較的關節對、平滑窗口等）
  ///
  /// 回傳 [YHeightDiffResponse]，包含時間序列的高度差資料。
  Future<YHeightDiffResponse> fetchYHeightDiff({
    required String sessionName,
    required YHeightDiffConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _yHeightDiffEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return YHeightDiffResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得空間頻譜 (Spatial Spectrum) 分析資料。
  ///
  /// 此 API 對身體運動軌跡在 XZ 或 YZ 平面的投影進行頻譜分析，
  /// 用於識別步態的週期性特徵（如步頻、擺動頻率等）。
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定，包含：
  ///   - projection: 投影平面 ('xz' 或 'yz')
  ///   - smoothWindow: 平滑窗口大小
  ///   - minVAbs / flatFrac: 訊號過濾閾值
  ///   - topK: 標註的峰值數量
  ///   - minDb / minFreq: 峰值檢測閾值
  ///
  /// 回傳 [SpatialSpectrumResponse]，包含頻率 vs. PSD (dB) 的曲線資料與峰值標註。
  Future<SpatialSpectrumResponse> fetchSpatialSpectrum({
    required String sessionName,
    required SpatialSpectrumConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _spatialSpectrumEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return SpatialSpectrumResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得多關節 FFT/PSD 頻譜分析資料。
  ///
  /// 此 API 對指定關節（或關節組合）的座標時間序列進行快速傅立葉變換 (FFT)，
  /// 輸出功率頻譜密度 (PSD)，用於分析各關節運動的頻率特徵。
  ///
  /// 支援的關節選取方式：
  /// - 單一關節: 如 25 (left_knee)
  /// - 關節對: 如 [23, 24] (left_hip + right_hip 的中點)
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定，包含：
  ///   - component: 分析的軸向 ('x', 'y', 'z')
  ///   - joints: 要分析的關節選取列表
  ///   - topK: 每條曲線最多標註的峰值數量
  ///   - minPeakDistanceRatio: 峰值之間的最小距離比例
  ///   - minDb / minFreq: 峰值檢測閾值
  ///
  /// 回傳 [MultiFftSeriesResponse]，包含各關節的頻率 vs. PSD (dB) 曲線與峰值標註。
  Future<MultiFftSeriesResponse> fetchMultiFftFromSeries({
    required String sessionName,
    required MultiFftFromSeriesConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _multiFftEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return MultiFftSeriesResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得每圈速度時空熱圖。
  ///
  /// 此 API 會將每圈的速度序列重採樣到固定寬度，並輸出可視化所需的色階範圍。
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定（包含投影平面、平滑視窗、閾值、重採樣寬度等）
  ///
  /// 回傳 [SpeedHeatmapResponse]，包含熱圖矩陣、轉彎區段標註與色階資訊。
  Future<SpeedHeatmapResponse> fetchSpeedHeatmap({
    required String sessionName,
    required SpeedHeatmapConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _speedHeatmapEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return SpeedHeatmapResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得每分鐘左右擺動期（swing）熱圖資料。
  ///
  /// 此 API 會將 session 按分鐘切分，回傳：
  /// - Left/Right 的 swing% 矩陣（2 x minutes）
  /// - Left/Right 的 swing 秒數矩陣（2 x minutes）
  ///
  /// - [sessionName]: 要分析的 session 名稱
  /// - [config]: 分析參數設定（平滑、投影平面、閾值、最多分鐘數等）
  ///
  /// 回傳 [SwingInfoHeatmapResponse]。
  Future<SwingInfoHeatmapResponse> fetchSwingInfoHeatmap({
    required String sessionName,
    required SwingInfoHeatmapConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _swingInfoHeatmapEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return SwingInfoHeatmapResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得 top-down 軌跡動畫資料包（前端自行渲染）。
  ///
  /// 後端回傳的 frames 為 uint16 little-endian + zlib + base64 的極簡 payload；
  /// 前端需再解壓/反量化才能畫出軌跡與播放 marker。
  Future<TrajectoryPayloadResponse> fetchTrajectoryPayload({
    required String sessionName,
    required TrajectoryPayloadConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _trajectoryPayloadEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return TrajectoryPayloadResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得步態週期相位分析資料。
  ///
  /// 此 API 分析左右腳的步態週期相位分佈，包含雙支撐期、單支撐期、擺動期等。
  Future<GaitCyclePhasesResponse> fetchGaitCyclePhases({
    required String sessionName,
    required GaitCyclePhasesConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _gaitCyclePhasesEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return GaitCyclePhasesResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// 取得每分鐘趨勢分析資料（速度與圈數）。
  ///
  /// 此 API 將 session 按分鐘切分，回傳每分鐘的平均速度與完成圈數。
  Future<MinutelyTrendResponse> fetchMinutelyTrend({
    required String sessionName,
    required MinutelyTrendConfig config,
  }) async {
    try {
      final response = await withApiRetry(
        () => _dio.post<Map<String, dynamic>>(
          _minutelyTrendEndpoint,
          queryParameters: {'session_name': sessionName},
          data: config.toJson(),
        ),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(message: '伺服器未回傳有效的資料。');
      }
      return MinutelyTrendResponse.fromJson(body);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

/// [StageAnalysisApiService] 的 Riverpod Provider。
///
/// 透過 [dioProvider] 注入 Dio 實例，確保所有 API 呼叫使用統一的 HTTP 設定。
final stageAnalysisApiServiceProvider = Provider<StageAnalysisApiService>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return StageAnalysisApiService(dio);
});
