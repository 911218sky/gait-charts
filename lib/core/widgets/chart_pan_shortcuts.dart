import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:gait_charts/app/theme.dart';

/// 圖表鍵盤平移捷徑元件。
///
/// 提供左右方向鍵平移與 focus 外框，讓可縮放圖表共用同一套鍵盤互動。
/// 點擊圖表取得焦點後，可用 ←/→ 平移視窗。
class ChartPanShortcuts extends StatefulWidget {
  const ChartPanShortcuts({
    required this.child,
    required this.onArrow,
    this.onHold,
    this.enabled = true,
    this.onEscape,
    this.focusNode,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.showFocusBorder = false,
    this.requestFocusOnPointerDown = true,
    this.holdDelay = const Duration(milliseconds: 200),
    super.key,
  });

  final Widget child;

  /// 是否啟用快捷鍵（未啟用時仍可顯示 focus 外框）。
  final bool enabled;

  /// 方向鍵觸發時呼叫：`-1` = 往左、`+1` = 往右。
  final ValueChanged<int> onArrow;

  /// 長按方向鍵時的連續平移 callback。
  ///
  /// - `step`: `-1` 往左、`+1` 往右
  /// - `dt`: 距上一個 tick 的時間差
  ///
  /// 未提供時長按會重複呼叫 [onArrow]。
  final void Function(int step, Duration dt)? onHold;

  /// Esc 觸發（常用於清 tooltip/游標）。
  final VoidCallback? onEscape;

  /// 若不提供，會由內部建立並管理生命週期。
  final FocusNode? focusNode;

  final BorderRadius borderRadius;
  final bool showFocusBorder;
  final bool requestFocusOnPointerDown;
  final Duration holdDelay;

  @override
  State<ChartPanShortcuts> createState() => _ChartPanShortcutsState();
}

class _ChartPanShortcutsState extends State<ChartPanShortcuts>
    with TickerProviderStateMixin {
  FocusNode? _internalNode;

  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  Timer? _holdTimer;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  int? _heldStep;

  @override
  void dispose() {
    _stopHold();
    _ticker?.dispose();
    _internalNode?.dispose();
    super.dispose();
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _heldStep = null;
    _lastElapsed = Duration.zero;
    _ticker?.stop();
  }

  void _startHold(int step) {
    if (!widget.enabled) {
      return;
    }

    if (_heldStep == step) {
      return;
    }

    _stopHold();
    _heldStep = step;

    // 先觸發一次離散移動，確保按下即有回饋
    widget.onArrow(step);

    // 延遲後進入 60fps 連續平移，比系統 key-repeat 更順暢
    _holdTimer = Timer(widget.holdDelay, () {
      if (!mounted || _heldStep == null) {
        return;
      }
      _ticker ??= createTicker((elapsed) {
        final currentStep = _heldStep;
        if (currentStep == null) {
          return;
        }
        if (_lastElapsed == Duration.zero) {
          _lastElapsed = elapsed;
          return;
        }
        final dt = elapsed - _lastElapsed;
        _lastElapsed = elapsed;
        if (dt <= Duration.zero) {
          return;
        }
        final onHold = widget.onHold;
        if (onHold != null) {
          onHold(currentStep, dt);
        } else {
          widget.onArrow(currentStep);
        }
      });
      _lastElapsed = Duration.zero;
      _ticker!.start();
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        widget.onEscape?.call();
      }
      return KeyEventResult.handled;
    }

    final isLeft = key == LogicalKeyboardKey.arrowLeft;
    final isRight = key == LogicalKeyboardKey.arrowRight;
    if (!isLeft && !isRight) {
      return KeyEventResult.ignored;
    }

    final step = isLeft ? -1 : 1;

    if (event is KeyDownEvent) {
      _startHold(step);
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) {
      // 由 ticker 處理連續平移，不依賴系統 repeat 率
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      if (_heldStep == step) {
        _stopHold();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.requestFocusOnPointerDown
          ? (_) => _node.requestFocus()
          : null,
      child: Focus(
        focusNode: _node,
        onKeyEvent: _onKeyEvent,
        child: widget.showFocusBorder
            ? AnimatedBuilder(
                animation: _node,
                builder: (context, child) {
                  final hasFocus = _node.hasFocus;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      border: hasFocus
                          ? Border.all(
                              color: colors.primary.withValues(alpha: 0.35),
                              width: 1,
                            )
                          : null,
                    ),
                    child: child,
                  );
                },
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}
