import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:window_manager/window_manager.dart';


/// Windows 無邊框自訂標題列（可拖曳、最小化/最大化/關閉）。
///
/// 設計風格：
/// - 類似 Vercel / 現代編輯器 (VS Code) 的極簡風格。
/// - 高度較扁 (32-38px)。
/// - 按鈕為方形且貼齊邊緣。
/// - 背景與 Scaffold 一致，視覺上更沉浸。
/// - 標題加入「打字機」效果，模擬啟動時的科技感 (打字 -> 停留 -> 刪除 -> 重複)，並隨機變換後綴。
class AppWindowTitleBar extends StatefulWidget {
  const AppWindowTitleBar({super.key, this.height = 38});

  final double height;

  @override
  State<AppWindowTitleBar> createState() => _AppWindowTitleBarState();
}

class _AppWindowTitleBarState extends State<AppWindowTitleBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typewriterController;

  // 基礎標題
  static const String _baseTitle = 'Gait Charts';
  
  // 隨機後綴詞庫 (科技感/狀態感)
  static const List<String> _suffixes = [
    '', // 偶爾只顯示標題
    ' // Analyzing',
    ' // Monitoring',
    ' // System Ready',
    ' // Processing',
    ' :: Waiting for input',
    ' :: Dashboard',
    ' :: Realsense Active',
    ' [LIVE]',
  ];

  String _currentFullText = _baseTitle;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // 初始動畫控制器
    // 這裡我們不使用 controller.repeat()，而是透過 StatusListener 手動控制循環，
    // 以便在每次循環間插入「換字」邏輯和「動態時長」。
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 監聽狀態以實現循環：打字 -> 停留 -> 刪除 -> 換字 -> 重複
    _typewriterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 打字完成 -> 停留 3 秒 -> 開始刪除
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) {
            // 刪除速度稍快一點 (每個字 30ms)
            _typewriterController.duration =
                Duration(milliseconds: _currentFullText.length * 30);
            _typewriterController.reverse();
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        // 刪除完成 -> 換字 -> 停留 0.5 秒 -> 開始打字
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              // 隨機挑選後綴
              final suffix = _suffixes[_random.nextInt(_suffixes.length)];
              _currentFullText = '$_baseTitle$suffix';
            });
            // 打字速度 (每個字 80ms + 基礎 500ms)
            _typewriterController.duration =
                Duration(milliseconds: 500 + _currentFullText.length * 80);
            _typewriterController.forward();
          }
        });
      }
    });

    // 啟動第一次動畫
    _typewriterController.forward();
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const SizedBox.shrink();
    }

    final colors = context.colorScheme;
    final backgroundColor = context.scaffoldBackgroundColor;

    return Container(
      height: widget.height,
      color: backgroundColor, // 與背景融合，不突兀
      child: Row(
        children: [
          // 1. 標題與 Logo 區域
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              children: [
                // 固定顯示的 Logo
                Icon(
                  Icons.insights,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),

                // 打字機文字效果
                AnimatedBuilder(
                  animation: _typewriterController,
                  builder: (context, child) {
                    // 計算目前顯示長度
                    final len = (_typewriterController.value * _currentFullText.length).round();
                    // 保護邊界
                    final safeLen = len.clamp(0, _currentFullText.length);
                    final text = _currentFullText.substring(0, safeLen);
                    
                    final isAnimating = _typewriterController.isAnimating;
                    
                    // 光標閃爍邏輯：
                    // - 動畫中 (打字/刪除)：恆亮
                    // - 靜止時 (停留)：閃爍
                    final bool showCursor;
                    if (isAnimating) {
                      showCursor = true; 
                    } else {
                      // 停留時閃爍 (約 500ms 一次)
                      showCursor = (DateTime.now().millisecondsSinceEpoch ~/ 500) % 2 == 0;
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                        // 模擬光標 (Cursor)
                        if (showCursor)
                          Container(
                            width: 2,
                            height: 14,
                            margin: const EdgeInsets.only(left: 2),
                            color: colors.primary,
                          )
                        else
                          const SizedBox(width: 4), 
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. 拖曳區域 (佔滿剩餘空間)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // 確保空白處也能感應
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: const SizedBox.expand(),
            ),
          ),

          // 3. 視窗控制按鈕群組 (Windows 10/11 風格)
          _WindowControlButton(
            icon: Icons.remove, // 最小化
            onTap: windowManager.minimize,
            isCloseButton: false,
          ),
          _MaximizeButton(
            // 最大化/還原需要根據狀態切換 icon
            onTap: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _WindowControlButton(
            icon: Icons.close, // 關閉
            onTap: () async => await windowManager.close(),
            isCloseButton: true,
          ),
        ],
      ),
    );
  }
}

/// 視窗控制按鈕 (最小化 / 關閉)。
class _WindowControlButton extends StatefulWidget {
  const _WindowControlButton({
    required this.icon,
    required this.onTap,
    this.isCloseButton = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isCloseButton;

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // 根據是否為「關閉按鈕」決定 Hover 顏色
    // Close: 紅底白字
    // Others: 淺灰底 (與 Theme 互動色一致)
    final hoverColor = widget.isCloseButton
        ? const Color(0xFFC42B1C) // Windows 標準關閉紅
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);

    final iconColor = _isHovered && widget.isCloseButton
        ? Colors.white
        : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46, // Windows 標準寬度通常是 46px
          height: double.infinity, // 填滿 bar 高度
          color: _isHovered ? hoverColor : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 16, // icon 不宜過大
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// 專門處理「最大化/還原」狀態切換的按鈕。
class _MaximizeButton extends StatefulWidget {
  const _MaximizeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton> with WindowListener {
  bool _isMaximized = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _updateState() async {
    final max = await windowManager.isMaximized();
    if (mounted && max != _isMaximized) {
      setState(() => _isMaximized = max);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hoverColor = theme.colorScheme.onSurface.withValues(alpha: 0.06);

    // 最大化時顯示「還原」icon (兩個方塊)，否則顯示「最大化」icon (一個方塊)
    // 這裡用 Material Icons 近似：
    // crop_square -> 最大化
    // filter_none (看起來像兩個疊在一起的方塊) -> 還原
    final effectiveIcon = _isMaximized ? Icons.filter_none : Icons.crop_square;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: double.infinity,
          color: _isHovered ? hoverColor : Colors.transparent,
          alignment: Alignment.center,
          // 如果是還原圖示，通常要轉一下或調整大小
          child: Transform.rotate(
            // filter_none 預設有點角度，把它轉正一點看起來比較像 Restore
            angle: _isMaximized ? 1.57 : 0,
            child: Icon(
              effectiveIcon,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
