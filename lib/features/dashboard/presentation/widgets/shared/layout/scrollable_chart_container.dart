import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 可捲動的圖表容器。
///
/// 在小螢幕（< 600px）時提供水平捲動功能，讓熱圖等寬度固定的圖表
/// 可以完整顯示而不會被裁切或壓縮。
///
/// 使用方式：
/// ```dart
/// ScrollableChartContainer(
///   minWidth: 800, // 圖表最小寬度
///   child: HeatmapChart(...),
/// )
/// ```
class ScrollableChartContainer extends StatelessWidget {
  const ScrollableChartContainer({
    required this.child,
    this.minWidth = 600,
    this.scrollDirection = Axis.horizontal,
    this.padding,
    super.key,
  });

  /// 圖表內容。
  final Widget child;

  /// 圖表最小寬度，當螢幕寬度小於此值時啟用捲動。
  final double minWidth;

  /// 捲動方向，預設為水平。
  final Axis scrollDirection;

  /// 內部 padding。
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // 大螢幕直接顯示
    if (!isMobile) {
      return padding != null
          ? Padding(padding: padding!, child: child)
          : child;
    }

    // 小螢幕啟用捲動，直接使用固定的 minWidth 作為寬度
    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      padding: padding,
      child: SizedBox(
        width: minWidth,
        child: child,
      ),
    );
  }
}

/// 帶有捲動提示的圖表容器。
///
/// 在小螢幕時顯示捲動提示，讓使用者知道可以左右滑動查看完整圖表。
class ScrollableChartContainerWithHint extends StatefulWidget {
  const ScrollableChartContainerWithHint({
    required this.child,
    this.minWidth = 600,
    this.hintText = '← 左右滑動查看完整圖表 →',
    this.padding,
    super.key,
  });

  /// 圖表內容。
  final Widget child;

  /// 圖表最小寬度。
  final double minWidth;

  /// 捲動提示文字。
  final String hintText;

  /// 內部 padding。
  final EdgeInsetsGeometry? padding;

  @override
  State<ScrollableChartContainerWithHint> createState() =>
      _ScrollableChartContainerWithHintState();
}

class _ScrollableChartContainerWithHintState
    extends State<ScrollableChartContainerWithHint> {
  bool _hasScrolled = false;

  void _onScroll() {
    if (!_hasScrolled) {
      setState(() => _hasScrolled = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final colors = context.colorScheme;
    final textTheme = context.textTheme;

    // 大螢幕直接顯示
    if (!isMobile) {
      return widget.padding != null
          ? Padding(padding: widget.padding!, child: widget.child)
          : widget.child;
    }

    // 小螢幕顯示捲動提示 + 可捲動容器
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 捲動提示（滑動後隱藏）
        if (!_hasScrolled)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe,
                  size: 16,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.hintText,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        // 可捲動的圖表
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                _onScroll();
              }
              return false;
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: widget.padding,
              child: SizedBox(
                width: widget.minWidth,
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
