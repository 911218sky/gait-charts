import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 管理資料提取設定狀態。
class ExtractConfigNotifier extends Notifier<ExtractConfig> {
  @override
  ExtractConfig build() => const ExtractConfig();

  void setForce(bool value) => state = state.copyWith(force: value);
  void setSkipFrames(int value) => state = state.copyWith(skipFrames: value);
  void setMaxFrames(int value) => state = state.copyWith(maxFrames: value);
  void setModelComplexity(int value) =>
      state = state.copyWith(modelComplexity: value);
  void setMinDetectionConfidence(double value) =>
      state = state.copyWith(minDetectionConfidence: value);
  void setMinTrackingConfidence(double value) =>
      state = state.copyWith(minTrackingConfidence: value);
  void setMaxConcurrency(int value) =>
      state = state.copyWith(maxConcurrency: value);
  void setCalibratePose(bool value) =>
      state = state.copyWith(calibratePose: value);
  void setSaveVideo(bool value) =>
      state = state.copyWith(saveVideo: value);
  void reset() => state = const ExtractConfig();
}

/// 暴露資料提取設定的 Provider。
final extractConfigProvider =
    NotifierProvider<ExtractConfigNotifier, ExtractConfig>(
      ExtractConfigNotifier.new,
    );

/// 控制資料提取流程的 Notifier，發送 API 並回報結果。
class ExtractionController extends Notifier<AsyncValue<ExtractResult?>> {
  DashboardRepository get _repository => ref.watch(dashboardRepositoryProvider);

  @override
  AsyncValue<ExtractResult?> build() {
    return const AsyncData<ExtractResult?>(null);
  }

  void _setStateIfMounted(AsyncValue<ExtractResult?> next) {
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// 提交提取請求。
  Future<void> submit({
    String? bagId,
    String? bagPath,
    String? sessionName,
    ExtractConfig? config,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.triggerExtraction(
        bagId: bagId,
        bagPath: bagPath,
        sessionName: sessionName,
        config: config,
      );
      _setStateIfMounted(AsyncData(result));
    } catch (error, stackTrace) {
      _setStateIfMounted(AsyncError(error, stackTrace));
    }
  }

  void reset() => state = const AsyncData<ExtractResult?>(null);
}

/// 提供 ExtractionController 的 Provider。
final extractionControllerProvider =
    NotifierProvider<ExtractionController, AsyncValue<ExtractResult?>>(
      ExtractionController.new,
    );

// ============================================================================
// 多檔案批次處理相關
// ============================================================================

/// 單一檔案的處理狀態
enum FileExtractionStatus {
  pending, // 等待處理
  running, // 處理中
  success, // 完成
  failed, // 失敗
}

/// 輸入來源類型：
/// - serverBagId：用後端提供的 bag_id（推薦、跨平台）
/// - localBagPath：用本機路徑 bag_path（僅桌面可用）
enum BagInputKind { serverBagId, localBagPath }

/// 單一檔案的處理項目
class FileExtractionItem {
  const FileExtractionItem({
    required this.kind,
    required this.input,
    this.bag,
    this.sessionName,
    this.status = FileExtractionStatus.pending,
    this.result,
    this.error,
  });

  final BagInputKind kind;

  /// `bag_id` 或 `bag_path`（依 [kind] 決定）。
  final String input;

  /// 伺服器清單挑選時會附帶 bag 的 meta（本機路徑模式通常為 null）。
  final BagFileItem? bag;
  final String? sessionName;
  final FileExtractionStatus status;
  final ExtractResult? result;
  final String? error;

  /// 用於 UI/Provider 的唯一識別 key（避免本機路徑與 bag_id 撞名）。
  String get key => switch (kind) {
        BagInputKind.serverBagId => 'id:$input',
        BagInputKind.localBagPath => 'path:$input',
      };

  String? get bagId => kind == BagInputKind.serverBagId ? input : null;

  String? get bagPath => kind == BagInputKind.localBagPath ? input : null;

  /// UI 顯示用的路徑/識別字串。
  String get displayPath => input;

  /// 從 bagId / name 提取顯示名稱（去掉 .bag 副檔名）。
  String get displayName {
    final sourceName = (bag?.name.trim().isNotEmpty ?? false)
        ? bag!.name
        : input.split(RegExp(r'[/\\]')).last;
    final fileName = sourceName.trim().isEmpty ? input : sourceName;
    if (fileName.toLowerCase().endsWith('.bag')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }

  FileExtractionItem copyWith({
    BagInputKind? kind,
    String? input,
    BagFileItem? bag,
    String? sessionName,
    FileExtractionStatus? status,
    ExtractResult? result,
    String? error,
  }) {
    return FileExtractionItem(
      kind: kind ?? this.kind,
      input: input ?? this.input,
      bag: bag ?? this.bag,
      sessionName: sessionName ?? this.sessionName,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// 批次處理的整體狀態
class BatchExtractionState {
  const BatchExtractionState({
    this.items = const [],
    this.isProcessing = false,
    this.maxConcurrency = 3,
  });

  final List<FileExtractionItem> items;
  final bool isProcessing;
  final int maxConcurrency;

  /// 計算已完成數量 (包含成功與失敗)
  int get completedCount => items
      .where(
        (item) =>
            item.status == FileExtractionStatus.success ||
            item.status == FileExtractionStatus.failed,
      )
      .length;

  /// 計算成功數量
  int get successCount =>
      items.where((item) => item.status == FileExtractionStatus.success).length;

  /// 計算失敗數量
  int get failedCount =>
      items.where((item) => item.status == FileExtractionStatus.failed).length;

  /// 正在處理中的數量
  int get runningCount =>
      items.where((item) => item.status == FileExtractionStatus.running).length;

  /// 是否全部完成
  bool get isAllCompleted => items.isNotEmpty && completedCount == items.length;

  BatchExtractionState copyWith({
    List<FileExtractionItem>? items,
    bool? isProcessing,
    int? maxConcurrency,
  }) {
    return BatchExtractionState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
      maxConcurrency: maxConcurrency ?? this.maxConcurrency,
    );
  }
}

/// 批次處理控制器
class BatchExtractionController extends Notifier<BatchExtractionState> {
  DashboardRepository get _repository => ref.watch(dashboardRepositoryProvider);

  bool _draining = false;
  final Set<Future<void>> _activeTasks = <Future<void>>{};
  ExtractConfig _lastConfig = const ExtractConfig();

  @override
  BatchExtractionState build() {
    return const BatchExtractionState();
  }

  void _setStateIfMounted(BatchExtractionState next) {
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// 新增多個伺服器 bag 到待處理佇列。
  void addBags(List<BagFileItem> bags) {
    final existingKeys = state.items.map((item) => item.key).toSet();
    final newItems = bags
        .where((bag) => bag.bagId.trim().isNotEmpty)
        .where((bag) => !existingKeys.contains('id:${bag.bagId}'))
        .map(
          (bag) => FileExtractionItem(
            kind: BagInputKind.serverBagId,
            input: bag.bagId,
            bag: bag,
            // 預設以檔名作為 session_name，仍可在 UI 手動覆寫
            sessionName: _defaultSessionName(bag.bagId),
          ),
        )
        .toList(growable: false);

    if (newItems.isEmpty) return;

    _setStateIfMounted(state.copyWith(items: [...state.items, ...newItems]));
  }

  /// 新增多個本機 bag 路徑到待處理佇列（僅桌面使用）。
  void addLocalFiles(List<String> bagPaths) {
    final existingKeys = state.items.map((item) => item.key).toSet();
    final newItems = bagPaths
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .where((p) => !existingKeys.contains('path:$p'))
        .map(
          (path) => FileExtractionItem(
            kind: BagInputKind.localBagPath,
            input: path,
            sessionName: _defaultSessionName(path),
          ),
        )
        .toList(growable: false);

    if (newItems.isEmpty) return;
    _setStateIfMounted(state.copyWith(items: [...state.items, ...newItems]));
  }

  /// 更新指定檔案的 session_name
  void setSessionName(String key, String? sessionName) {
    if (state.isProcessing) return;
    FileExtractionItem? current;
    for (final it in state.items) {
      if (it.key == key) {
        current = it;
        break;
      }
    }
    if (current == null) return;
    final normalized = _normalizeSessionName(sessionName, input: current.input);
    _updateItem(key, (it) => it.copyWith(sessionName: normalized));
  }

  /// 移除指定檔案 (僅能移除 pending 狀態的)
  void removeItem(String key) {
    final items = state.items
        .where(
          (item) =>
              item.key != key ||
              item.status != FileExtractionStatus.pending,
        )
        .toList();
    state = state.copyWith(items: items);
  }

  /// 清空所有檔案
  void clearAll() {
    if (state.isProcessing) return;
    _setStateIfMounted(const BatchExtractionState());
  }

  /// 開始批次處理（會處理目前所有 pending 的項目）。
  Future<void> startProcessing({ExtractConfig? config}) async {
    if (state.items.isEmpty) return;
    await _ensureDrain(config ?? const ExtractConfig());
  }

  /// 重新嘗試單一檔案。
  ///
  /// - 會把該項目重設為 pending，並交由佇列依 maxConcurrency 自動處理
  Future<void> retryItem({
    required String key,
    ExtractConfig? config,
  }) async {
    FileExtractionItem? current;
    for (final it in state.items) {
      if (it.key == key) {
        current = it;
        break;
      }
    }
    if (current == null) return;

    // 只有 failed 才需要重試；其他狀態直接忽略（避免重複點擊造成混亂）。
    if (current.status != FileExtractionStatus.failed) return;

    _updateItem(
      key,
      (i) => i.copyWith(
        status: FileExtractionStatus.pending,
        result: null,
        error: null,
      ),
    );

    await _ensureDrain(config ?? const ExtractConfig());
  }

  /// 一鍵重試所有失敗項目（只會重試 failed，不影響 success / pending / running）。
  Future<void> retryFailed({ExtractConfig? config}) async {
    if (state.items.isEmpty) return;
    if (!state.items.any((it) => it.status == FileExtractionStatus.failed)) {
      return;
    }

    final nextItems = state.items
        .map(
          (it) => it.status == FileExtractionStatus.failed
              ? it.copyWith(
                  status: FileExtractionStatus.pending,
                  result: null,
                  error: null,
                )
              : it,
        )
        .toList(growable: false);
    _setStateIfMounted(state.copyWith(items: nextItems));

    await _ensureDrain(config ?? const ExtractConfig());
  }

  Future<void> _ensureDrain(ExtractConfig config) async {
    _lastConfig = config;
    if (_draining) {
      return;
    }

    _draining = true;
    _setStateIfMounted(state.copyWith(isProcessing: true));
    try {
      await _drainLoop();
    } finally {
      _activeTasks.clear();
      _draining = false;
      _setStateIfMounted(state.copyWith(isProcessing: false));
    }
  }

  FileExtractionItem? _nextPending() {
    for (final it in state.items) {
      if (it.status == FileExtractionStatus.pending) {
        return it;
      }
    }
    return null;
  }

  Future<void> _drainLoop() async {
    while (ref.mounted) {
      final maxConcurrency = _lastConfig.maxConcurrency;

      // 盡可能補滿併發池；新的 pending（例如使用者重試）會在下一輪被抓到。
      while (_activeTasks.length < maxConcurrency) {
        final next = _nextPending();
        if (next == null) break;

        late final Future<void> task;
        task = _processItem(next, _lastConfig).whenComplete(() {
          _activeTasks.remove(task);
        });
        _activeTasks.add(task);
      }

      if (_activeTasks.isEmpty) {
        // 沒有執行中任務且也沒有 pending 就結束。
        if (_nextPending() == null) {
          return;
        }
      } else {
        await Future.any(_activeTasks);
      }
    }
  }

  /// 處理單一檔案
  Future<void> _processItem(
    FileExtractionItem item,
    ExtractConfig config,
  ) async {
    // 更新狀態為處理中
    _updateItem(
      item.key,
      (i) => i.copyWith(status: FileExtractionStatus.running, error: null),
    );

    try {
      final result = await _repository.triggerExtraction(
        bagId: item.bagId,
        bagPath: item.bagPath,
        sessionName: item.sessionName,
        config: config,
      );

      // 更新狀態為成功
      _updateItem(
        item.key,
        (i) => i.copyWith(
          status: FileExtractionStatus.success,
          result: result,
          error: null,
        ),
      );
    } catch (error) {
      // 更新狀態為失敗
      _updateItem(
        item.key,
        (i) => i.copyWith(
          status: FileExtractionStatus.failed,
          error: error.toString(),
        ),
      );
    }
  }

  /// 更新單一項目
  void _updateItem(
    String key,
    FileExtractionItem Function(FileExtractionItem) updater,
  ) {
    if (!ref.mounted) {
      return;
    }
    final items = state.items.map((item) {
      if (item.key == key) {
        return updater(item);
      }
      return item;
    }).toList();
    _setStateIfMounted(state.copyWith(items: items));
  }

  /// 重設狀態
  void reset() {
    if (state.isProcessing) return;
    _setStateIfMounted(const BatchExtractionState());
  }
}

String _defaultSessionName(String bagPath) {
  final fileName = bagPath.split(RegExp(r'[/\\]')).last;
  if (fileName.toLowerCase().endsWith('.bag')) {
    return fileName.substring(0, fileName.length - 4);
  }
  return fileName;
}

String _normalizeSessionName(String? raw, {required String input}) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return _defaultSessionName(input);
  }
  return trimmed;
}

/// 批次處理控制器 Provider
final batchExtractionControllerProvider =
    NotifierProvider<BatchExtractionController, BatchExtractionState>(
      BatchExtractionController.new,
    );

/// 以 bagPath 作為 key 的 items map，方便 UI 用 select 做「單列更新」。
///
/// - Map 會在 items 任何欄位變更時重建（建立新 Map），但 value 會盡量重用既有 item 物件。
/// - UI 若使用 `.select((m) => m[bagPath])`，只有該 bagPath 的 item 變更才會重建對應列。
final batchExtractionItemsByKeyProvider =
    Provider<Map<String, FileExtractionItem>>((ref) {
  final items = ref.watch(
    batchExtractionControllerProvider.select((state) => state.items),
  );
  return <String, FileExtractionItem>{
    for (final item in items) item.key: item,
  };
});
