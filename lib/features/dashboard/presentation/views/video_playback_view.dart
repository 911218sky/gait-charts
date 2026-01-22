import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/domain/models/video_source.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/session_detail_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_availability_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_player_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_seek_request_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_user_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/views/video_playback/video_playback.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/platform_video_player.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/video_user_info_card.dart';

/// Dashboard 內嵌的影片播放頁面。
///
/// 支援桌面版（水平佈局）和手機版（垂直佈局）兩種模式。
/// 提供 session 搜尋、影片播放、使用者資訊顯示等功能。
class VideoPlaybackView extends ConsumerStatefulWidget {
  const VideoPlaybackView({
    required this.sessionController,
    required this.onLoadSession,
    super.key,
  });

  final TextEditingController sessionController;
  final VoidCallback onLoadSession;

  @override
  ConsumerState<VideoPlaybackView> createState() => _VideoPlaybackViewState();
}

class _VideoPlaybackViewState extends ConsumerState<VideoPlaybackView> {
  final GlobalKey<PlatformVideoPlayerState> _playerKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  VideoPlayerState _playerState = const VideoPlayerState();
  bool _showControls = true;
  bool _isFullscreen = false;
  String? _currentSession;

  @override
  void initState() {
    super.initState();
    final session = widget.sessionController.text.trim();
    if (session.isNotEmpty) {
      _currentSession = session;
    }
    // 自動聚焦以接收鍵盤事件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // 退出時恢復正常方向和系統 UI
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _focusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // 播放器控制
  // ─────────────────────────────────────────────────────────────

  void _onStateChanged(VideoPlayerState state) {
    final wasInitialized = _playerState.isInitialized;
    setState(() => _playerState = state);
    
    // 播放器剛初始化完成時，檢查是否有待處理的跳轉請求
    if (!wasInitialized && state.isInitialized) {
      final seekRequest = ref.read(videoSeekRequestProvider);
      if (seekRequest != null) {
        // 延遲一幀確保播放器完全就緒
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _playerKey.currentState != null) {
            _seekTo(seekRequest.targetDuration);
            ref.read(videoSeekRequestProvider.notifier).clear();
          }
        });
      }
    }
  }

  void _togglePlayPause() => _playerKey.currentState?.togglePlayPause();
  void _seekTo(Duration position) => _playerKey.currentState?.seekTo(position);
  void _setVolume(double volume) => _playerKey.currentState?.setVolume(volume);
  void _setPlaybackSpeed(double speed) =>
      _playerKey.currentState?.setPlaybackSpeed(speed);

  /// 相對跳轉，正數往前、負數往後
  void _seekRelative(int seconds) {
    final newPosition = _playerState.position + Duration(seconds: seconds);
    // 確保不會跳到負數或超過影片長度
    final clamped = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(
        0,
        _playerState.duration.inMilliseconds,
      ),
    );
    _seekTo(clamped);
  }

  // ─────────────────────────────────────────────────────────────
  // 鍵盤快捷鍵
  // ─────────────────────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        _togglePlayPause();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _seekRelative(-5);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _seekRelative(5);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _setVolume((_playerState.volume + 0.1).clamp(0.0, 1.0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _setVolume((_playerState.volume - 0.1).clamp(0.0, 1.0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyM:
        _setVolume(_playerState.volume > 0 ? 0 : 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyF:
        _toggleFullscreen();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (_isFullscreen) {
          _toggleFullscreen();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 全螢幕控制
  // ─────────────────────────────────────────────────────────────

  void _toggleFullscreen() {
    final isMobile = context.isMobile;

    if (!_isFullscreen) {
      if (isMobile) {
        // 手機版：強制橫向 + 隱藏系統 UI
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } else {
      if (isMobile) {
        // 恢復正常
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }

    setState(() => _isFullscreen = !_isFullscreen);
  }

  // ─────────────────────────────────────────────────────────────
  // Session 載入
  // ─────────────────────────────────────────────────────────────

  void _loadSession() {
    final session = widget.sessionController.text.trim();
    if (session.isEmpty) return;
    setState(() => _currentSession = session);
    widget.onLoadSession();
  }

  void _clearSession() {
    widget.sessionController.clear();
    setState(() => _currentSession = null);
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final config = ref.watch(appConfigProvider);
    final isMobile = context.isMobile;

    // 監聽影片跳轉請求（從其他頁面如分析頁面發送）
    ref.listen<VideoSeekRequest?>(videoSeekRequestProvider, (prev, next) {
      if (next != null && _playerKey.currentState != null) {
        _seekTo(next.targetDuration);
        ref.read(videoSeekRequestProvider.notifier).clear();
      }
    });

    // 取得 session 詳情和使用者資訊
    final sessionDetailAsync = _currentSession != null
        ? ref.watch(sessionDetailProvider(_currentSession))
        : const AsyncValue<RealsenseSessionItem?>.data(null);

    final bagFilename =
        sessionDetailAsync.whenData((s) => s?.bagFilename).value;

    final userAsync = (bagFilename != null && bagFilename.isNotEmpty)
        ? ref.watch(findUserByBagProvider(bagFilename))
        : const AsyncValue<FindUserByBagResponse?>.data(null);

    // 全螢幕模式
    if (_isFullscreen && _currentSession != null) {
      return _buildFullscreenPlayer(config);
    }

    // 手機版：垂直佈局
    if (isMobile) {
      return _buildMobileLayout(colors, config, sessionDetailAsync, userAsync);
    }

    // 桌面版：水平佈局
    return _buildDesktopLayout(colors, config, sessionDetailAsync, userAsync);
  }

  Widget _buildDesktopLayout(
    ColorScheme colors,
    AppConfig config,
    AsyncValue<RealsenseSessionItem?> sessionDetailAsync,
    AsyncValue<FindUserByBagResponse?> userAsync,
  ) {
    return GestureDetector(
      onTap: _focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 主要區域
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    VideoToolbar(
                      controller: widget.sessionController,
                      onLoadSession: _loadSession,
                      onClear: _clearSession,
                      isMobile: false,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _currentSession == null
                          ? const VideoEmptyState()
                          : _buildVideoPlayer(config),
                    ),
                  ],
                ),
              ),
            ),
            // 右側資訊欄
            Container(
              width: 360,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(left: BorderSide(color: colors.outlineVariant)),
              ),
              child: _buildUserInfoPanel(userAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    ColorScheme colors,
    AppConfig config,
    AsyncValue<RealsenseSessionItem?> sessionDetailAsync,
    AsyncValue<FindUserByBagResponse?> userAsync,
  ) {
    return GestureDetector(
      onTap: _focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            // 影片區域（16:9）
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.width * 9 / 16,
              child: _currentSession == null
                  ? const VideoEmptyState()
                  : _buildMobileVideoPlayer(config),
            ),
            // 下方內容
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  VideoToolbar(
                    controller: widget.sessionController,
                    onLoadSession: _loadSession,
                    onClear: _clearSession,
                    isMobile: true,
                  ),
                  const SizedBox(height: 16),
                  _buildMobileUserInfo(sessionDetailAsync, userAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 播放器區塊
  // ─────────────────────────────────────────────────────────────

  Widget _buildVideoPlayer(AppConfig config) {
    final videoAvailability =
        ref.watch(videoAvailabilityProvider(_currentSession));

    return videoAvailability.when(
      data: (availability) {
        if (availability == null) {
          return const VideoErrorState(
            icon: Icons.error_outline,
            title: 'Session 不存在',
            message: '找不到此 Session',
          );
        }
        if (!availability.hasVideo) {
          return const VideoErrorState(
            icon: Icons.videocam_off_outlined,
            title: '此 Session 未生成影片',
            message: '此 Session 在擷取時未啟用影片儲存',
          );
        }
        if (!availability.videoExists) {
          return const VideoErrorState(
            icon: Icons.broken_image_outlined,
            title: '影片檔案遺失',
            message: '影片檔案可能已被刪除或移動',
          );
        }

        final source = VideoSource.fromSession(
          baseUrl: config.baseUrl,
          sessionName: _currentSession!,
        );

        return VideoPlayerSection(
          playerKey: _playerKey,
          source: source,
          sessionName: _currentSession!,
          playerState: _playerState,
          showControls: _showControls,
          onStateChanged: _onStateChanged,
          onTogglePlayPause: _togglePlayPause,
          onSeek: _seekTo,
          onVolumeChanged: _setVolume,
          onSpeedChanged: _setPlaybackSpeed,
          onFullscreen: _toggleFullscreen,
          onShowControlsChanged: (show) => setState(() => _showControls = show),
          onTap: _focusNode.requestFocus,
        );
      },
      loading: () => const VideoLoadingState(),
      error: (error, _) => VideoErrorState(
        icon: Icons.error_outline,
        title: '載入失敗',
        message: error.toString(),
      ),
    );
  }

  Widget _buildMobileVideoPlayer(AppConfig config) {
    final videoAvailability =
        ref.watch(videoAvailabilityProvider(_currentSession));

    return videoAvailability.when(
      data: (availability) {
        if (availability == null) {
          return const VideoErrorState(
            icon: Icons.error_outline,
            title: 'Session 不存在',
            message: '找不到此 Session',
          );
        }
        if (!availability.hasVideo) {
          return const VideoErrorState(
            icon: Icons.videocam_off_outlined,
            title: '此 Session 未生成影片',
            message: '此 Session 在擷取時未啟用影片儲存',
          );
        }
        if (!availability.videoExists) {
          return const VideoErrorState(
            icon: Icons.broken_image_outlined,
            title: '影片檔案遺失',
            message: '影片檔案可能已被刪除或移動',
          );
        }

        final source = VideoSource.fromSession(
          baseUrl: config.baseUrl,
          sessionName: _currentSession!,
        );

        return MobileVideoPlayerSection(
          playerKey: _playerKey,
          source: source,
          sessionName: _currentSession!,
          playerState: _playerState,
          showControls: _showControls,
          onStateChanged: _onStateChanged,
          onTogglePlayPause: _togglePlayPause,
          onSeek: _seekTo,
          onVolumeChanged: _setVolume,
          onSpeedChanged: _setPlaybackSpeed,
          onFullscreen: _toggleFullscreen,
          onShowControlsChanged: (show) => setState(() => _showControls = show),
          onTap: _focusNode.requestFocus,
        );
      },
      loading: () => const VideoLoadingState(),
      error: (error, _) => VideoErrorState(
        icon: Icons.error_outline,
        title: '載入失敗',
        message: error.toString(),
      ),
    );
  }

  Widget _buildFullscreenPlayer(AppConfig config) {
    final source = VideoSource.fromSession(
      baseUrl: config.baseUrl,
      sessionName: _currentSession!,
    );

    return VideoFullscreenPlayer(
      playerKey: _playerKey,
      source: source,
      sessionName: _currentSession!,
      playerState: _playerState,
      showControls: _showControls,
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      onStateChanged: _onStateChanged,
      onTogglePlayPause: _togglePlayPause,
      onSeek: _seekTo,
      onVolumeChanged: _setVolume,
      onSpeedChanged: _setPlaybackSpeed,
      onExitFullscreen: _toggleFullscreen,
      onShowControlsChanged: (show) => setState(() => _showControls = show),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 使用者資訊
  // ─────────────────────────────────────────────────────────────

  Widget _buildUserInfoPanel(AsyncValue<FindUserByBagResponse?> userAsync) {
    if (_currentSession == null) {
      return const VideoUserNoSessionCard();
    }

    if (userAsync.isLoading) {
      return const VideoUserLoadingCard();
    }

    if (userAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: context.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              '載入失敗',
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    final userResponse = userAsync.value;
    if (userResponse == null ||
        !userResponse.found ||
        userResponse.user == null) {
      return const VideoUserEmptyCard();
    }

    return VideoUserInfoCard(
      user: userResponse.user!,
      sessions: userResponse.sessions,
      currentSessionName: _currentSession,
      onSessionTap: (sessionName) {
        widget.sessionController.text = sessionName;
        _loadSession();
      },
    );
  }

  Widget _buildMobileUserInfo(
    AsyncValue<RealsenseSessionItem?> sessionDetailAsync,
    AsyncValue<FindUserByBagResponse?> userAsync,
  ) {
    if (_currentSession == null) return const SizedBox.shrink();

    if (sessionDetailAsync.isLoading || userAsync.isLoading) {
      return const MobileUserInfoLoading();
    }

    final userResponse = userAsync.value;
    if (userResponse == null ||
        !userResponse.found ||
        userResponse.user == null) {
      return const SizedBox.shrink();
    }

    return MobileUserInfoSection(user: userResponse.user!);
  }
}
