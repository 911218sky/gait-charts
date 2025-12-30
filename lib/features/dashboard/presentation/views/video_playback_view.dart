import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/features/dashboard/domain/models/video_source.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/video/video_player_provider.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/platform_video_player.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/video/video_player_controls.dart';

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
      default:
        return KeyEventResult.ignored;
    }
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

    return GestureDetector(
      // 點擊任何地方都聚焦，確保可以接收鍵盤事件
      onTap: _focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            // 頂部工具列
            _buildToolbar(context, colors),
            // 影片播放區域
            Expanded(
              child: _currentSession == null
                  ? _buildEmptyState(context, colors)
                  : _buildVideoPlayer(context, colors, config),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SessionAutocompleteField(
              controller: widget.sessionController,
              labelText: 'Session 名稱',
              onSubmitted: (_) => _loadSession(),
              onSuggestionSelected: (_) => _loadSession(),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _showSessionPicker,
            icon: const Icon(Icons.search),
            label: const Text('瀏覽 Sessions'),
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
    final source = VideoSource.fromSession(
      baseUrl: config.baseUrl,
      sessionName: _currentSession!,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          _togglePlayPause();
        },
        child: Container(
          color: context.scaffoldBackgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 影片播放器
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
                      // Session 名稱（左上角）
                      Positioned(
                        top: 12,
                        left: 12,
                        child: AnimatedOpacity(
                          opacity: _showControls || !_playerState.isPlaying ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentSession!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
