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
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_user_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/platform_video_player.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/video_player_controls.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/video_user_info_card.dart';

/// Dashboard 內嵌的影片播放頁面。
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
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onStateChanged(VideoPlayerState state) {
    setState(() => _playerState = state);
  }

  void _togglePlayPause() {
    _playerKey.currentState?.togglePlayPause();
  }

  void _seekTo(Duration position) {
    _playerKey.currentState?.seekTo(position);
  }

  void _setVolume(double volume) {
    _playerKey.currentState?.setVolume(volume);
  }

  void _setPlaybackSpeed(double speed) {
    _playerKey.currentState?.setPlaybackSpeed(speed);
  }

  void _seekRelative(int seconds) {
    final newPosition = _playerState.position + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(
        0,
        _playerState.duration.inMilliseconds,
      ),
    );
    _seekTo(clamped);
  }

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

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
  }

  void _loadSession() {
    final session = widget.sessionController.text.trim();
    if (session.isEmpty) return;
    setState(() {
      _currentSession = session;
    });
    widget.onLoadSession();
  }

  Future<void> _showSessionPicker() async {
    final result = await SessionPickerDialog.showForVideo(context);
    if (result != null && mounted) {
      widget.sessionController.text = result.sessionName;
      _loadSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final config = ref.watch(appConfigProvider);

    // 取得 session 詳情和使用者資訊
    final sessionDetailAsync = _currentSession != null
        ? ref.watch(sessionDetailProvider(_currentSession))
        : const AsyncValue<RealsenseSessionItem?>.data(null);
    
    // 直接使用後端回傳的 bagFilename（若無則不查詢）
    final bagFilename = sessionDetailAsync.whenData((s) => s?.bagFilename).value;
    
    final userAsync = (bagFilename != null && bagFilename.isNotEmpty)
        ? ref.watch(findUserByBagProvider(bagFilename))
        : const AsyncValue<FindUserByBagResponse?>.data(null);

    // 全螢幕模式
    if (_isFullscreen && _currentSession != null) {
      return _buildFullscreenPlayer(context, colors, config);
    }

    return GestureDetector(
      // 點擊任何地方都聚焦，確保可以接收鍵盤事件
      onTap: _focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 主要區域：搜尋列 + 影片播放
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 頂部搜尋列 (整合在內容區塊上方)
                    _buildCompactToolbar(context, colors),
                    const SizedBox(height: 12),
                    // 影片播放區域
                    Expanded(
                      child: _currentSession == null
                          ? _buildEmptyState(context, colors)
                          : _buildVideoPlayer(context, colors, config),
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
                border: Border(
                  left: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: _buildUserInfoPanel(
                context, 
                colors, 
                sessionDetailAsync,
                userAsync,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToolbar(BuildContext context, ColorScheme colors) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search, color: colors.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SessionAutocompleteField(
                      controller: widget.sessionController,
                      labelText: '搜尋或輸入 Session 名稱...',
                      onSubmitted: (_) => _loadSession(),
                      onSuggestionSelected: (_) => _loadSession(),
                      // 移除原本的 TextField 裝飾，使其融入 Toolbar
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                        hintText: '搜尋或輸入 Session 名稱...',
                      ),
                    ),
                  ),
                  if (widget.sessionController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.sessionController.clear();
                        setState(() => _currentSession = null);
                      },
                    ),
                  IconButton(
                    onPressed: _loadSession,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: '載入',
                    color: colors.primary,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _showSessionPicker,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('瀏覽'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '選擇一個 Session 來播放影片',
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '輸入 session 名稱或點擊「瀏覽 Sessions」選擇',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(
    BuildContext context,
    ColorScheme colors,
    AppConfig config,
  ) {
    // 先檢查影片可用性
    final videoAvailability = ref.watch(videoAvailabilityProvider(_currentSession));
    
    return videoAvailability.when(
      data: (availability) {
        // Session 不存在
        if (availability == null) {
          return _buildErrorState(
            context,
            colors,
            icon: Icons.error_outline,
            title: 'Session 不存在',
            message: '找不到此 Session',
          );
        }
        
        // 沒有影片
        if (!availability.hasVideo) {
          return _buildErrorState(
            context,
            colors,
            icon: Icons.videocam_off_outlined,
            title: '此 Session 未生成影片',
            message: '此 Session 在萃取時未啟用影片儲存',
          );
        }
        
        // 影片檔案遺失
        if (!availability.videoExists) {
          return _buildErrorState(
            context,
            colors,
            icon: Icons.broken_image_outlined,
            title: '影片檔案遺失',
            message: '影片檔案可能已被刪除或移動',
          );
        }
        
        // 影片可播放，顯示播放器
        final source = VideoSource.fromSession(
          baseUrl: config.baseUrl,
          sessionName: _currentSession!,
        );

        return _buildVideoPlayerWidget(context, colors, source);
      },
      loading: () => _buildLoadingState(context, colors),
      error: (error, stack) => _buildErrorState(
        context,
        colors,
        icon: Icons.error_outline,
        title: '載入失敗',
        message: error.toString(),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '檢查影片可用性...',
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: colors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerWidget(
    BuildContext context,
    ColorScheme colors,
    VideoSource source,
  ) {

    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          // 如果點擊的是控制列區域外，切換播放/暫停
          // 但這裡我們先簡單切換，因為 InteractiveViewer 可能會吃掉一些手勢
          _togglePlayPause();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 影片層 (包含 Zoom)
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PlatformVideoPlayer(
                      key: _playerKey,
                      source: source,
                      onStateChanged: _onStateChanged,
                      autoPlay: true,
                    ),
                  ),
                ),
              ),

              // 2. 緩衝指示器
              if (_playerState.isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // 3. 中央播放按鈕（只在已初始化、未播放、未緩衝時顯示）
              if (_playerState.isInitialized && 
                  !_playerState.isPlaying && 
                  !_playerState.isBuffering)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 64,
                      onPressed: _togglePlayPause,
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    ),
                  ),
                ),

              // 4. Session 名稱（左上角浮層）
              Positioned(
                top: 24,
                left: 24,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.movie_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _currentSession!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. 控制列（底部）
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showControls || !_playerState.isPlaying ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: VideoPlayerControls(
                    state: _playerState,
                    onPlayPause: _togglePlayPause,
                    onSeek: _seekTo,
                    onVolumeChanged: _setVolume,
                    onSpeedChanged: _setPlaybackSpeed,
                    onFullscreen: _toggleFullscreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 全螢幕播放器。
  Widget _buildFullscreenPlayer(
    BuildContext context,
    ColorScheme colors,
    AppConfig config,
  ) {
    final source = VideoSource.fromSession(
      baseUrl: config.baseUrl,
      sessionName: _currentSession!,
    );

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _showControls = true),
        onExit: (_) => setState(() => _showControls = false),
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            _togglePlayPause();
          },
          onDoubleTap: _toggleFullscreen,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 影片層
                Center(
                  child: PlatformVideoPlayer(
                    key: _playerKey,
                    source: source,
                    onStateChanged: _onStateChanged,
                    autoPlay: true,
                  ),
                ),

                // 緩衝指示器
                if (_playerState.isBuffering)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // 中央播放按鈕（只在已初始化、未播放、未緩衝時顯示）
                if (_playerState.isInitialized && 
                    !_playerState.isPlaying && 
                    !_playerState.isBuffering)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 80,
                        onPressed: _togglePlayPause,
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      ),
                    ),
                  ),

                // Session 名稱（左上角）
                Positioned(
                  top: 24,
                  left: 24,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.movie_outlined, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _currentSession!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 退出全螢幕按鈕（右上角）
                Positioned(
                  top: 24,
                  right: 24,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: _toggleFullscreen,
                      icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 32),
                      tooltip: '退出全螢幕 (ESC)',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),

                // 控制列（底部）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls || !_playerState.isPlaying ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: VideoPlayerControls(
                      state: _playerState,
                      onPlayPause: _togglePlayPause,
                      onSeek: _seekTo,
                      onVolumeChanged: _setVolume,
                      onSpeedChanged: _setPlaybackSpeed,
                      onFullscreen: _toggleFullscreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 建立使用者資訊側邊欄。
  Widget _buildUserInfoPanel(
    BuildContext context,
    ColorScheme colors,
    AsyncValue<RealsenseSessionItem?> sessionDetailAsync,
    AsyncValue<FindUserByBagResponse?> userAsync,
  ) {
    // 尚未選擇 session
    if (_currentSession == null) {
      return const VideoUserNoSessionCard();
    }
    
    // 載入中狀態
    if (sessionDetailAsync.isLoading || userAsync.isLoading) {
      return const VideoUserLoadingCard();
    }

    // 錯誤狀態
    if (sessionDetailAsync.hasError || userAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: colors.error,
            ),
            const SizedBox(height: 12),
            Text(
              '載入失敗',
              style: context.textTheme.titleSmall?.copyWith(
                color: colors.error,
              ),
            ),
          ],
        ),
      );
    }

    // 取得使用者資料
    final userResponse = userAsync.value;
    if (userResponse == null || !userResponse.found || userResponse.user == null) {
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
}
