import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/core/widgets/async_error_view.dart';
import 'package:gait_charts/core/widgets/async_loading_view.dart';

typedef AsyncDataBuilder<T> = Widget Function(BuildContext context, T data);
typedef AsyncEmptyPredicate<T> = bool Function(T data);
typedef AsyncEmptyBuilder = Widget Function(BuildContext context);

/// 統一處理「AsyncValue 顯示」的共用 Widget：
/// - loading：顯示 loader（但若已有 failure 快取，直接顯示錯誤避免一直轉圈）
/// - error：顯示 AsyncErrorView
/// - data：交給 dataBuilder
///
/// 搭配 [fetchWithFailureGate] 使用，可確保：
/// - 相同條件的 request 失敗後，不會被 rebuild 反覆觸發 API
/// - UI 也不會卡在 loading 轉圈
class AsyncRequestView<T> extends ConsumerWidget {
  const AsyncRequestView({
    required this.requestId,
    required this.value,
    required this.dataBuilder,
    required this.onRetry,
    super.key,
    this.loadingLabel,
    this.isEmpty,
    this.emptyBuilder,
  });

  final String requestId;
  final AsyncValue<T> value;
  final AsyncDataBuilder<T> dataBuilder;
  final VoidCallback onRetry;
  final String? loadingLabel;
  final AsyncEmptyPredicate<T>? isEmpty;
  final AsyncEmptyBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = ref.watch(requestFailureProvider(requestId));

    Widget buildError(Object error) {
      return AsyncErrorView(
        error: error,
        onRetry: () {
          ref.read(requestFailureStoreProvider.notifier).clearFailure(requestId);
          onRetry();
        },
      );
    }

    // 若已經有失敗紀錄，且目前又進入 loading（例如 refresh/rebuild），直接顯示錯誤避免無限轉圈。
    if (value.isLoading && failure != null) {
      return buildError(failure.error);
    }

    return value.when(
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }
        return dataBuilder(context, data);
      },
      loading: () => AsyncLoadingView(label: loadingLabel),
      error: (error, stackTrace) => buildError(error),
    );
  }
}


