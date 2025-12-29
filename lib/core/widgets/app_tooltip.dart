import 'package:flutter/material.dart';

/// 統一的 Tooltip 包裝元件。
///
/// 包一層方便未來集中調整 tooltip 行為。
class AppTooltip extends StatelessWidget {
  const AppTooltip({
    required this.message,
    required this.child,
    super.key,
    this.richMessage,
    this.constraints,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.decoration,
    this.textStyle,
    this.waitDuration,
    this.showDuration,
    this.triggerMode,
    this.enableTapToDismiss = true,
    this.excludeFromSemantics,
  });

  final String message;
  final InlineSpan? richMessage;
  final Widget child;

  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? verticalOffset;
  final bool? preferBelow;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final Duration? waitDuration;
  final Duration? showDuration;
  final TooltipTriggerMode? triggerMode;
  final bool enableTapToDismiss;

  /// 若外部要強制控制語意行為，可明確指定此值。
  final bool? excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final effectiveExclude = excludeFromSemantics ?? false;

    return Tooltip(
      message: message,
      richMessage: richMessage,
      constraints: constraints,
      padding: padding,
      margin: margin,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
      decoration: decoration,
      textStyle: textStyle,
      waitDuration: waitDuration,
      showDuration: showDuration,
      triggerMode: triggerMode,
      enableTapToDismiss: enableTapToDismiss,
      excludeFromSemantics: effectiveExclude,
      child: child,
    );
  }
}
