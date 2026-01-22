import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gait_charts/features/dashboard/domain/models/video_source.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_player_provider.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:video_player_win/video_player_win.dart' as win;

/// 跨平台影片播放器 Widget。
/// 
/// Windows 使用 video_player_win，其他平台使用 video_player。
/// 支援連線中斷偵測與重試功能。
class PlatformVideoPlayer extends StatefulWidget {
  const PlatformVideoPlayer({
    required this.source,
    required this.onStateChanged,
    this.autoPlay = false,
    super.key,
  });

  final VideoSource source;
  final ValueChanged<VideoPlayerState> onStateChanged;
  final bool autoPlay;

  @override
  State<PlatformVideoPlayer> createState() => PlatformVideoPlayerState();
}

class PlatformVideoPlayerState extends State<PlatformVideoPlayer> {
  // Windows 播放器
  win.WinVideoPlayerController? _winController;
  
  // 其他平台播放器
  vp.VideoPlayerController? _vpController;
  
  VideoPlayerState _state = const VideoPlayerState();
  Timer? _positionTimer;
  
  /// 上次更新的 position，用於減少不必要的 setState
  Duration _lastPosition = Duration.zero;
  
  /// Buffering 超時偵測（連線中斷判斷）
  Timer? _bufferingTimeoutTimer;
  static const _bufferingTimeout = Duration(seconds: 15);
  DateTime? _bufferingStartTime;

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  /// 切換影片時的延遲，讓瀏覽器/系統有時間清理舊連線。
  static const _switchDelay = Duration(milliseconds: 100);
  
  /// 追蹤是否正在切換影片，避免重複觸發。
  bool _isSwitching = false;

  @override
  void didUpdateWidget(PlatformVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.uri != widget.source.uri) {
      _switchVideo();
    }
  }
  
  /// 切換影片時，先清理舊的再載入新的，中間加入短暫延遲。
  Future<void> _switchVideo() async {
    if (_isSwitching) return;
    _isSwitching = true;
    
    // 清理舊的播放器
    _disposePlayer();
    
    // 短暫延遲，讓底層有時間取消進行中的 HTTP 請求
    await Future<void>.delayed(_switchDelay);
    
    // 確認 widget 還在，再初始化新的
    if (!mounted) {
      _isSwitching = false;
      return;
    }
    
    await _initializePlayer();
    _isSwitching = false;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  /// 同步清理播放器資源。
  /// 
  /// 注意：這裡使用同步方式清理，避免 async gap 導致的競態條件。
  /// pause() 和 dispose() 的 Future 會被觸發但不等待完成。
  void _disposePlayer() {
    _positionTimer?.cancel();
    _positionTimer = null;
    _bufferingTimeoutTimer?.cancel();
    _bufferingTimeoutTimer = null;
    _bufferingStartTime = null;
    
    // 先移除 listener，避免 dispose 過程中觸發 callback
    if (_winController != null) {
      final controller = _winController!;
      _winController = null;
      controller.removeListener(_onWinPlayerUpdate);
      // 先 pause 再 dispose，讓底層有機會取消進行中的請求
      controller.pause().then((_) => controller.dispose()).ignore();
    }
    if (_vpController != null) {
      final controller = _vpController!;
      _vpController = null;
      controller.removeListener(_onVpPlayerUpdate);
      // 先 pause 再 dispose，讓底層有機會取消進行中的請求
      controller.pause().then((_) => controller.dispose()).ignore();
    }
  }

  Future<void> _initializePlayer() async {
    // 延遲到下一幀再更新狀態，避免在 build 階段觸發 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateState(_state.copyWith(
        source: widget.source,
        isInitialized: false,
        clearError: true,
      ));
    });

    try {
      if (_isWindows) {
        await _initWindowsPlayer();
      } else {
        await _initCrossPlayer();
      }
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateState(_state.copyWith(
          errorMessage: '無法載入影片：$e',
        ));
      });
    }
  }

  Future<void> _initWindowsPlayer() async {
    final controller = win.WinVideoPlayerController.networkUrl(
      Uri.parse(widget.source.uri),
    );
    _winController = controller;

    await controller.initialize();

    if (!mounted) return;

    _updateState(_state.copyWith(
      isInitialized: true,
      duration: controller.value.duration,
    ));

    controller.addListener(_onWinPlayerUpdate);

    // 定時更新播放位置（降低頻率以優化性能）
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_winController == null || !mounted) return;
      final pos = _winController!.value.position;
      // 只在 position 變化超過 200ms 時才更新，減少不必要的 setState
      if ((pos - _lastPosition).abs() > const Duration(milliseconds: 200)) {
        _lastPosition = pos;
        _updateState(_state.copyWith(
          position: pos,
          isBuffering: _winController!.value.isBuffering,
        ));
      }
    });

    if (widget.autoPlay) {
      await controller.play();
    }
  }

  Future<void> _initCrossPlayer() async {
    final vp.VideoPlayerController controller;
    
    if (widget.source.type == VideoSourceType.network) {
      controller = vp.VideoPlayerController.networkUrl(
        Uri.parse(widget.source.uri),
        httpHeaders: kIsWeb ? const {'Accept': 'video/mp4,video/*'} : const {},
        videoPlayerOptions: vp.VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
    } else {
      controller = vp.VideoPlayerController.file(
        File(widget.source.uri),
        videoPlayerOptions: vp.VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
    }
    
    _vpController = controller;

    try {
      await controller.initialize();
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateState(_state.copyWith(
          errorMessage: '影片載入失敗：$e',
        ));
      });
      return;
    }

    if (!mounted) return;

    _updateState(_state.copyWith(
      isInitialized: true,
      duration: controller.value.duration,
    ));

    controller.addListener(_onVpPlayerUpdate);

    if (widget.autoPlay) {
      await controller.play();
    }
  }

  void _onWinPlayerUpdate() {
    if (_winController == null || !mounted) return;
    final value = _winController!.value;
    
    // 偵測 buffering 超時（可能是連線中斷）
    _handleBufferingTimeout(value.isBuffering);
    
    _updateState(_state.copyWith(
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      position: value.position,
      duration: value.duration,
    ));
  }
  
  /// 處理 buffering 超時偵測。
  /// 如果持續 buffering 超過 [_bufferingTimeout]，視為連線中斷。
  void _handleBufferingTimeout(bool isBuffering) {
    if (isBuffering) {
      // 開始 buffering，記錄開始時間
      _bufferingStartTime ??= DateTime.now();
      
      // 啟動超時計時器
      _bufferingTimeoutTimer ??= Timer(_bufferingTimeout, () {
        if (!mounted) return;
        if (_state.isBuffering && _bufferingStartTime != null) {
          final elapsed = DateTime.now().difference(_bufferingStartTime!);
          if (elapsed >= _bufferingTimeout) {
            _updateState(_state.copyWith(
              errorMessage: '影片載入逾時，請檢查網路連線',
            ));
          }
        }
      });
    } else {
      // 停止 buffering，重置計時
      _bufferingStartTime = null;
      _bufferingTimeoutTimer?.cancel();
      _bufferingTimeoutTimer = null;
    }
  }

  void _onVpPlayerUpdate() {
    if (_vpController == null || !mounted) return;
    final value = _vpController!.value;
    
    // 偵測 buffering 超時（可能是連線中斷）
    _handleBufferingTimeout(value.isBuffering);
    
    _updateState(_state.copyWith(
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      position: value.position,
      duration: value.duration,
      errorMessage: value.hasError ? value.errorDescription : null,
    ));
  }

  void _updateState(VideoPlayerState newState) {
    if (!mounted) return;
    // 只在狀態真的改變時才 setState
    if (_state != newState) {
      setState(() => _state = newState);
      widget.onStateChanged(newState);
    }
  }

  /// 播放/暫停切換。
  Future<void> togglePlayPause() async {
    // 確保影片已初始化
    if (!_state.isInitialized) return;
    
    if (_isWindows && _winController != null) {
      if (_winController!.value.isPlaying) {
        await _winController!.pause();
      } else {
        await _winController!.play();
      }
    } else if (_vpController != null) {
      if (_vpController!.value.isPlaying) {
        await _vpController!.pause();
      } else {
        await _vpController!.play();
      }
    }
  }

  /// 跳轉到指定位置。
  Future<void> seekTo(Duration position) async {
    if (!_state.isInitialized) return;
    
    if (_isWindows && _winController != null) {
      await _winController!.seekTo(position);
    } else if (_vpController != null) {
      await _vpController!.seekTo(position);
    }
  }

  /// 設定音量（0.0 ~ 1.0）。
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (!_state.isInitialized) {
      _updateState(_state.copyWith(volume: clamped));
      return;
    }
    
    if (_isWindows && _winController != null) {
      await _winController!.setVolume(clamped);
    } else if (_vpController != null) {
      await _vpController!.setVolume(clamped);
    }
    _updateState(_state.copyWith(volume: clamped));
  }

  /// 設定播放速度。
  Future<void> setPlaybackSpeed(double speed) async {
    if (!_state.isInitialized) {
      _updateState(_state.copyWith(playbackSpeed: speed));
      return;
    }
    
    if (_isWindows && _winController != null) {
      await _winController!.setPlaybackSpeed(speed);
    } else if (_vpController != null) {
      await _vpController!.setPlaybackSpeed(speed);
    }
    _updateState(_state.copyWith(playbackSpeed: speed));
  }

  /// 重新載入影片（用於錯誤後重試）。
  Future<void> retry() async {
    if (_isSwitching) return;
    _isSwitching = true;
    
    _disposePlayer();
    _state = const VideoPlayerState();
    
    // 短暫延遲，讓底層清理完成
    await Future<void>.delayed(_switchDelay);
    
    if (!mounted) {
      _isSwitching = false;
      return;
    }
    
    await _initializePlayer();
    _isSwitching = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_state.hasError) {
      return _ErrorDisplay(
        message: _state.errorMessage!,
        onRetry: retry,
      );
    }

    if (!_state.isInitialized) {
      return const _LoadingDisplay();
    }

    if (_isWindows && _winController != null) {
      // 使用 RepaintBoundary 減少不必要的重繪
      return RepaintBoundary(
        child: win.WinVideoPlayer(_winController!),
      );
    }

    if (_vpController != null) {
      return RepaintBoundary(
        child: AspectRatio(
          aspectRatio: _vpController!.value.aspectRatio,
          child: vp.VideoPlayer(_vpController!),
        ),
      );
    }

    return _ErrorDisplay(
      message: '播放器初始化失敗',
      onRetry: retry,
    );
  }
}

/// 載入中顯示。
class _LoadingDisplay extends StatelessWidget {
  const _LoadingDisplay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('載入影片中...'),
        ],
      ),
    );
  }
}

/// 錯誤顯示。
class _ErrorDisplay extends StatelessWidget {
  const _ErrorDisplay({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // 判斷是否為「沒有影片」的錯誤
    final lowerMessage = message.toLowerCase();
    final isNoVideo = lowerMessage.contains('video file not opened') ||
        lowerMessage.contains('file not found') ||
        lowerMessage.contains('not found') ||
        lowerMessage.contains('not available') ||
        lowerMessage.contains('404') ||
        lowerMessage.contains('corrupted') ||
        lowerMessage.contains('not supported') ||
        lowerMessage.contains('mf_media_engine');
    
    // 判斷是否為連線問題
    final isConnectionError = lowerMessage.contains('逾時') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('network') ||
        lowerMessage.contains('socket');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isNoVideo
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoVideo 
                    ? Icons.videocam_off_outlined 
                    : isConnectionError
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                size: 40,
                color: isNoVideo
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.red.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isNoVideo 
                  ? '此 Session 沒有影片' 
                  : isConnectionError
                      ? '連線中斷'
                      : '無法載入影片',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // 重試按鈕（連線錯誤或一般錯誤時顯示）
            if (!isNoVideo && onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重試'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
