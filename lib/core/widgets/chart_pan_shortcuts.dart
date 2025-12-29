import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:gait_charts/app/theme.dart';

/// 圖表鍵盤平移捷徑（左右方向鍵）+ focus 外框。
///
/// 設計目標：
/// - 任何「可縮放的圖表」都能用同一套鍵盤/焦點互動
/// - 點一下圖表即可取得焦點，接著用 ←/→ 平移視窗（由呼叫端決定如何平移）
/// - 避免把 feature-specific 的邏輯塞進 core：這裡只負責快捷鍵與 focus UI
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

  /// 長按方向鍵時的連續平移（用於「順滑」手感）。
  ///
  /// - `step`: `-1` = 往左、`+1` = 往右
  /// - `dt`: 距離上一個 tick 的時間差
  ///
  /// 若未提供，長按時會退化成重複呼叫 [onArrow]（可能不夠順或移動太大）。
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

    // 先做一次「離散」移動：按一下就會有明確回饋。
    widget.onArrow(step);

    // 延遲後進入連續平移，手感更順（類似 key-repeat，但以 60fps 觸發）。
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
      // 交給 ticker 處理連續平移，避免依賴作業系統 repeat 率造成卡頓。
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
