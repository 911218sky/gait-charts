import 'package:flutter/material.dart';

/// 右上角的影片緞帶標示。
class VideoRibbon extends StatelessWidget {
  const VideoRibbon({required this.colors, super.key});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          size: 18,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}
