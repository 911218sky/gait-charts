import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// 顯示首字母的圓角方形頭像。
///
/// 常用於列表項目、卡片中顯示名稱的首字母縮寫。
/// 支援選中狀態的視覺變化。
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    required this.text,
    this.size = 36,
    this.isSelected = false,
    this.borderRadius = 8,
    this.selectedColor,
    super.key,
  });

  /// 要顯示的文字，會取第一個字元並轉為大寫。
  final String text;

  /// 頭像尺寸（寬高相同）。
  final double size;

  /// 是否為選中狀態。
  final bool isSelected;

  /// 圓角半徑。
  final double borderRadius;

  /// 選中時的文字顏色，預設使用 primary color。
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final initial = text.isNotEmpty ? text[0].toUpperCase() : '?';
    
    final textColor = isSelected 
        ? (selectedColor ?? colors.primary) 
        : colors.onSurfaceVariant;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.surfaceMedium,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
