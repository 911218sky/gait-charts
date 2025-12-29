import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 一個具有流動漸層背景與網格的組件，用於登入畫面的底層。
class AdminLoginBackground extends StatefulWidget {
  const AdminLoginBackground({required this.child, super.key});

  final Widget child;

  @override
  State<AdminLoginBackground> createState() => _AdminLoginBackgroundState();
}

class _AdminLoginBackgroundState extends State<AdminLoginBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ValueNotifier<Offset> _mousePos = ValueNotifier(Offset.zero);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    // 不啟動動畫 (.repeat())，保持靜態
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    
    // 背景底色
    final backgroundColor = isDark ? const Color(0xFF050505) : const Color(0xFFF0F0F2);
    // 網格顏色：顯著提升不透明度，並加粗線條
    final gridColor = isDark 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.1);

    return MouseRegion(
      onHover: (event) {
        _mousePos.value = event.localPosition;
      },
      child: Stack(
        children: [
          // 1. 底色
          Container(color: backgroundColor),

          // 2. 網格背景
          Positioned.fill(
            child: ValueListenableBuilder<Offset>(
              valueListenable: _mousePos,
              builder: (context, mousePos, _) {
                return CustomPaint(
                  painter: _GridPainter(
                    color: gridColor,
                    spacing: 50.0, //稍微加大間距讓格子更明顯
                    mousePos: mousePos,
                    highlightColor: colorScheme.primary,
                  ),
                );
              },
            ),
          ),

          // 3. 流動的光影 - 主色
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // 靜態位置，不再隨 _controller.value 變化
              // 使用固定值 0.25 (或任意 t) 來定格在某個好看的角度
              const t = 0.25; 
              final alignX = 0.7 * cos(t * 2 * pi);
              final alignY = 0.6 * sin(t * 2 * pi) + 0.2 * cos(t * 4 * pi);
              
              return Align(
                alignment: Alignment(alignX, alignY),
                child: Container(
                  width: 800,
                  height: 800,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              );
            },
          ),

          // 4. 流動的光影 - 輔助色
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // 靜態位置
              const t = 0.25;
              final alignX = -0.6 * cos(t * 2 * pi + 1.5);
              final alignY = 0.6 * sin(t * 3 * pi) - 0.2;
              
              return Align(
                alignment: Alignment(alignX, alignY),
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.tertiary.withValues(alpha: isDark ? 0.12 : 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // 5. 滑鼠跟隨光暈 (Ambient Light)
          ValueListenableBuilder<Offset>(
            valueListenable: _mousePos,
            builder: (context, mousePos, _) {
              // 讓光暈中心稍微偏移滑鼠，增加自然感（或直接置中）
              return Positioned(
                left: mousePos.dx - 400,
                top: mousePos.dy - 400,
                child: IgnorePointer(
                  child: Container(
                    width: 800,
                    height: 800,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 6. 上層內容
          widget.child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final Offset mousePos;
  final Color highlightColor;

  const _GridPainter({
    required this.color,
    required this.spacing,
    required this.mousePos,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 繪製基礎淡網格
    final basePaint = Paint()
      ..color = color
      ..strokeWidth = 1;

    _drawGrid(canvas, size, basePaint);

    // 2. 繪製滑鼠高亮區域的網格 (使用 Shader 遮罩)
    // 只有在滑鼠移入時才繪製 (Offset.zero 可能是初始值，但這裡簡單假設都會繪製)
    final highlightPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..shader = ui.Gradient.radial(
        mousePos,
        300, // 高亮半徑
        [
          highlightColor.withValues(alpha: 0.3), // 中心亮度
          highlightColor.withValues(alpha: 0.0), // 邊緣完全透明
        ],
      );

    _drawGrid(canvas, size, highlightPaint);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    // 畫垂直線
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // 畫水平線
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return color != oldDelegate.color ||
        spacing != oldDelegate.spacing ||
        mousePos != oldDelegate.mousePos;
  }
}