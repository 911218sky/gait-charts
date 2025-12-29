import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 記錄「某個 requestId 在特定參數指紋下」的最後一次失敗。
///
/// 設計目的：
/// - 避免後端在連續失敗時，被 UI/Provider rebuild 反覆觸發同一支 API。
/// - 失敗後 UI 應直接顯示錯誤，不要一直轉圈；只有使用者按「重試」才再送一次。
@immutable
class RequestFailure {
  const RequestFailure({
    required this.fingerprint,
    required this.error,
    required this.stackTrace,
  });

  /// 用來辨識「同一組請求條件」的指紋（例如 session + config 組合）。
  final int fingerprint;

  final Object error;
  final StackTrace stackTrace;
}

class RequestFailureStoreNotifier extends Notifier<Map<String, RequestFailure>> {
  @override
  Map<String, RequestFailure> build() => const {};

  RequestFailure? getFailure(String requestId) => state[requestId];

  void setFailure({
    required String requestId,
    required int fingerprint,
    required Object error,
    required StackTrace stackTrace,
  }) {
    state = {
      ...state,
      requestId: RequestFailure(
        fingerprint: fingerprint,
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }

  void clearFailure(String requestId) {
    if (!state.containsKey(requestId)) return;
    final next = {...state}..remove(requestId);
    state = next;
  }
}

/// 全域的失敗快取（key = requestId）。
final requestFailureStoreProvider =
    NotifierProvider<RequestFailureStoreNotifier, Map<String, RequestFailure>>(
      RequestFailureStoreNotifier.new,
    );

/// 取得單一 requestId 的失敗紀錄（用 select 避免不必要 rebuild）。
final requestFailureProvider = Provider.family<RequestFailure?, String>((
  ref,
  requestId,
) {
  return ref.watch(
    requestFailureStoreProvider.select((map) => map[requestId]),
  );
});

/// 用於 FutureProvider 的共用包裝：
/// - 若相同 fingerprint 曾失敗，直接丟出同樣錯誤（不再打 API）
/// - 成功則清除 failure
/// - 失敗則寫入 failure
Future<T> fetchWithFailureGate<T>(
  Ref ref, {
  required String requestId,
  required int fingerprint,
  required Future<T> Function() fetch,
}) async {
  final lastFailure = ref.read(requestFailureStoreProvider)[requestId];
  if (lastFailure != null && lastFailure.fingerprint == fingerprint) {
    Error.throwWithStackTrace(lastFailure.error, lastFailure.stackTrace);
  }

  try {
    final result = await fetch();
    ref.read(requestFailureStoreProvider.notifier).clearFailure(requestId);
    return result;
  } catch (error, stackTrace) {
    ref.read(requestFailureStoreProvider.notifier).setFailure(
          requestId: requestId,
          fingerprint: fingerprint,
          error: error,
          stackTrace: stackTrace,
        );
    Error.throwWithStackTrace(error, stackTrace);
  }
}


