import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gait_charts/core/extensions/build_context_extensions.dart';

export 'package:gait_charts/core/extensions/build_context_extensions.dart';

// 類似 Vercel 風格的深色設計 Token
const _primaryColor = Colors.white; // 白色作為主要顏色
const _backgroundColor = Colors.black; // 純黑背景
const _surfaceContainer = Color(0xFF0A0A0A); // 稍微淺一點的黑色
const _surfaceElevated = Color(0xFF111111); // 卡片用的深灰色
const _outlineColor = Color(0xFF333333); // 微妙的邊框顏色
const _darkSurfaceLow = Color(0xFF0F0F10); // dark surface low（中性灰階）
const _darkSurface = Color(0xFF141416); // dark surface（對話框/容器底）
const _darkSurfaceHigh = Color(0xFF1C1C1F); // dark surface high（hover/更亮層）
const _darkOutlineVariant = Color(0xFF2A2A2E); // dark outline variant（更細緻）
const _darkMutedColor = Color(0xFFA1A1AA); // dark onSurfaceVariant（Zinc 400）
const _criticalColor = Color(0xFFFF4545); // 錯誤紅色
const _successColor = Color(0xFF00E054); // 成功綠色
const _warningColor = Color(0xFFF5A623); // 警告橘色

// 類似 Vercel 風格的淺色設計 Token（改用 Zinc 色系，中性且更舒適現代）
const _lightPrimaryColor = Color(0xFF09090B); // Zinc 950 (深黑，用於主要文字與按鈕)
const _lightBrandColor = Color(0xFF2563EB); // Blue 600 (互動/高亮 accent，讓白色風格更現代)
const _lightBackgroundColor = Color(0xFFFAFAFA); // Zinc 50 (極淡灰背景，比純白更舒適)
const _lightSurfaceColor = Colors.white; // 卡片表面 (純白，與背景形成層次)
const _lightSurfaceField = Color(0xFFF4F4F5); // Zinc 100 (輸入框、內嵌區塊背景)
const _lightOutlineColor = Color(0xFFE4E4E7); // Zinc 200 (細微邊框)
const _lightOutlineStrong = Color(0xFFD4D4D8); // Zinc 300 (較深邊框/控制項邊框)
const _lightMutedColor = Color(0xFF71717A); // Zinc 500 (次要文字)
const _lightMutedForeground = Color(0xFFA1A1AA); // Zinc 400 (禁用/佔位文字)

// 亮色專屬強調色 (保持原本的調整，與 Zinc 搭配依然合適)
const _lightSuccessColor = Color(0xFF16A34A); // Tailwind green-600
const _lightWarningColor = Color(0xFFD97706); // Tailwind amber-600
const _lightCriticalColor = Color(0xFFDC2626); // Tailwind red-600

// Shape tokens（深/淺色共用，確保外觀一致）
const _kRadiusButton = 6.0;
const _kRadiusCard = 8.0;
const _kRadiusDialog = 12.0;

/// Heatmap 使用的 viridis 調色盤（取樣自常用的 Matplotlib viridis）。
/// 這組顏色從低值的紫色一路過渡到高值的黃色，適合連續量的可視化。
const _viridisColors = <Color>[
  Color(0xFF440154),
  Color(0xFF482878),
  Color(0xFF3E4989),
  Color(0xFF31688E),
  Color(0xFF26828E),
  Color(0xFF1F9E89),
  Color(0xFF35B779),
  Color(0xFF6DCD59),
  Color(0xFFB4DE2C),
  Color(0xFFFDE725),
];

/// 建立儀表板使用的淺色主題，提供與深色一致的設計語言。
ThemeData buildLightTheme() {
  // 注意：
  // - 改用 Zinc 色系 (Neutral) 取代原本的 Slate (Blue-ish)，視覺上更乾淨舒適。
  // - 保持 Vercel 風格的高對比文字與極簡線條。
  final scheme = ColorScheme.fromSeed(
    seedColor: _lightBrandColor,
    brightness: Brightness.light,
  ).copyWith(
    // 互動色：使用品牌藍，避免全 UI 都是黑灰，讓 light mode 更有現代感。
    primary: _lightBrandColor,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFDBEAFE), // Blue 100
    onPrimaryContainer: const Color(0xFF1E3A8A), // Blue 900
    secondary: _lightBrandColor,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFDBEAFE),
    onSecondaryContainer: const Color(0xFF1E3A8A),
    tertiary: _lightBrandColor,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFDBEAFE),
    onTertiaryContainer: const Color(0xFF1E3A8A),
    surface: _lightSurfaceColor,
    onSurface: _lightPrimaryColor,
    surfaceBright: _lightSurfaceColor,
    surfaceDim: _lightSurfaceField,
    surfaceContainerHighest: _lightSurfaceField,
    onSurfaceVariant: _lightMutedColor,
    outline: _lightOutlineStrong, // 改用較強的 outline 作為預設邊框
    outlineVariant: _lightOutlineColor, // 較弱的作為輔助
    error: _criticalColor,
    onError: Colors.white,
    errorContainer: const Color(0xFFFEE2E2), // Red 100
    onErrorContainer: _criticalColor,
    inverseSurface: _lightPrimaryColor,
    onInverseSurface: Colors.white,
    inversePrimary: _lightBrandColor,
    shadow: Colors.black.withValues(alpha: 0.1),
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
    // fixed roles
    primaryFixed: _lightSurfaceField,
    primaryFixedDim: _lightOutlineColor,
    onPrimaryFixed: _lightPrimaryColor,
    onPrimaryFixedVariant: _lightPrimaryColor,
    secondaryFixed: _lightSurfaceField,
    secondaryFixedDim: _lightOutlineColor,
    onSecondaryFixed: _lightPrimaryColor,
    onSecondaryFixedVariant: _lightPrimaryColor,
    tertiaryFixed: _lightSurfaceField,
    tertiaryFixedDim: _lightOutlineColor,
    onTertiaryFixed: _lightPrimaryColor,
    onTertiaryFixedVariant: _lightPrimaryColor,
    surfaceContainerLowest: _lightSurfaceColor,
    surfaceContainerLow: const Color(0xFFFFFFFF), // 純白
    surfaceContainer: const Color(0xFFF4F4F5), // Zinc 100
    surfaceContainerHigh: const Color(0xFFE4E4E7), // Zinc 200
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
  );

  final textTheme = GoogleFonts.interTextTheme(
    base.textTheme,
  ).apply(displayColor: _lightPrimaryColor, bodyColor: _lightPrimaryColor);

  return base.copyWith(
    scaffoldBackgroundColor: _lightBackgroundColor,
    // 注意：Theme 切換時會走 ThemeData.lerp()，因此 light/dark 的 TextTheme 需要一致。
    // 這裡同時設定 textTheme / primaryTextTheme，避免只靠預設導致 inherit 不一致。
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    // 全域互動色：Vercel 風格的黑色低透明度
    hoverColor: _lightPrimaryColor.withValues(alpha: 0.04),
    splashColor: _lightPrimaryColor.withValues(alpha: 0.06),
    highlightColor: _lightPrimaryColor.withValues(alpha: 0.05),
    // focus 改用品牌色：更現代且可用性更好（容易辨識焦點）
    focusColor: _lightBrandColor.withValues(alpha: 0.14),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: _lightBackgroundColor,
      foregroundColor: _lightPrimaryColor,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: _lightOutlineColor)),
    ),
    cardTheme: CardThemeData(
      color: _lightSurfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadiusCard),
        side: const BorderSide(color: _lightOutlineColor, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _lightOutlineColor,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, // 輸入框保持純白
      hintStyle: const TextStyle(color: _lightMutedForeground),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
        borderSide: const BorderSide(color: _lightOutlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
        borderSide: const BorderSide(color: _lightOutlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
        borderSide: const BorderSide(color: _lightBrandColor, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _lightOutlineColor;
        }
        if (states.contains(WidgetState.selected)) {
          return _lightBrandColor;
        }
        return _lightOutlineStrong;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white.withValues(alpha: 0.7);
        }
        return Colors.white;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return _lightPrimaryColor.withValues(alpha: 0.10);
        }
        return null;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return _lightOutlineStrong;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: _lightOutlineStrong),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _lightBrandColor;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _lightBrandColor;
        }
        return _lightOutlineStrong;
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: _lightBrandColor.withValues(alpha: 0.12),
        selectedForegroundColor: _lightPrimaryColor,
        backgroundColor: Colors.transparent,
        foregroundColor: _lightMutedColor,
        side: const BorderSide(color: _lightOutlineColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(
          inherit: false,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _lightBackgroundColor,
      indicatorColor: _lightBrandColor.withValues(alpha: 0.10),
      selectedIconTheme: const IconThemeData(color: _lightPrimaryColor),
      unselectedIconTheme: const IconThemeData(color: _lightMutedColor),
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: GoogleFonts.inter(
        color: _lightPrimaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: _lightMutedColor,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _lightBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: _lightBrandColor.withValues(alpha: 0.14),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _lightPrimaryColor);
        }
        return const IconThemeData(color: _lightMutedColor);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            color: _lightPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }
        return GoogleFonts.inter(
          color: _lightMutedColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
        foregroundColor: _lightPrimaryColor,
        side: const BorderSide(color: _lightOutlineStrong),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightMutedColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _lightPrimaryColor,
        hoverColor: _lightPrimaryColor.withValues(alpha: 0.06),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: _lightBrandColor),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: _lightBrandColor,
      inactiveTrackColor: _lightMutedColor.withValues(alpha: 0.25),
      disabledActiveTrackColor: _lightMutedColor.withValues(alpha: 0.20),
      disabledInactiveTrackColor: _lightMutedColor.withValues(alpha: 0.12),
      thumbColor: _lightBrandColor,
      disabledThumbColor: _lightMutedColor.withValues(alpha: 0.45),
      overlayColor: _lightBrandColor.withValues(alpha: 0.12),
      valueIndicatorColor: _lightBrandColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      activeTickMarkColor: Colors.white.withValues(alpha: 0.65),
      inactiveTickMarkColor: _lightMutedColor.withValues(alpha: 0.35),
      disabledActiveTickMarkColor: _lightMutedColor.withValues(alpha: 0.25),
      disabledInactiveTickMarkColor: _lightMutedColor.withValues(alpha: 0.18),
      trackHeight: 4,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      side: const BorderSide(color: _lightOutlineColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
      ),
      labelStyle: const TextStyle(color: _lightPrimaryColor, fontSize: 13, fontWeight: FontWeight.w500),
      selectedColor: _lightPrimaryColor,
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _lightPrimaryColor,
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
    tooltipTheme: base.tooltipTheme,
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: _lightSurfaceColor,
      surfaceTintColor: Colors.transparent,
      textStyle: const TextStyle(color: _lightPrimaryColor),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _lightOutlineColor),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: _lightSurfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadiusDialog),
        side: const BorderSide(color: _lightOutlineColor),
      ),
    ),
    dividerColor: _lightOutlineColor,
    iconTheme: const IconThemeData(color: _lightPrimaryColor),
    extensions: const <ThemeExtension<dynamic>>[
      DashboardAccentColors(
        success: _lightSuccessColor,
        warning: _lightWarningColor,
        danger: _lightCriticalColor,
      ),
      DashboardHeatmapPalette(colors: _viridisColors),
    ],
  );
}

/// 建立預設的深色主題，貼近 Vercel 風格。
ThemeData buildDarkTheme() {
  // 深色模式：明確覆寫 surfaceContainer*，避免 fromSeed 生成帶偏色的 surface 角色。
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0A0A0A),
    brightness: Brightness.dark,
  ).copyWith(
    primary: _primaryColor,
    onPrimary: Colors.black,
    secondary: const Color(0xFF9CA3AF),
    onSecondary: Colors.black,
    surface: _darkSurface,
    onSurface: Colors.white,
    surfaceBright: _darkSurfaceHigh,
    surfaceDim: _surfaceContainer,
    surfaceContainerLowest: _surfaceContainer,
    surfaceContainerLow: _darkSurfaceLow,
    surfaceContainer: _surfaceElevated,
    surfaceContainerHigh: _darkSurfaceHigh,
    surfaceContainerHighest: const Color(0xFF232326),
    onSurfaceVariant: _darkMutedColor,
    outline: _outlineColor,
    outlineVariant: _darkOutlineVariant,
    error: _criticalColor,
    onError: Colors.black,
    inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: const Color(0xFF9CA3AF),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  // 關鍵：不要用 ThemeData.dark(...) 當 base。
  // ThemeData.dark 與 ThemeData(colorScheme: ...) 的預設 TextTheme/typography
  // 在 lerp 時可能出現 TextStyle.inherit 不一致，導致切換主題直接拋例外。
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
  );

  final textTheme = GoogleFonts.interTextTheme(
    base.textTheme,
  ).apply(bodyColor: Colors.white, displayColor: Colors.white);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: _backgroundColor,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: _backgroundColor,
      foregroundColor: Colors.white,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: _outlineColor)),
    ),
    cardTheme: CardThemeData(
      color: _surfaceElevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadiusCard),
        side: const BorderSide(color: _outlineColor),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceContainer,
      hintStyle: const TextStyle(color: Color(0xFF444444)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
        borderSide: const BorderSide(color: _outlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
        borderSide: const BorderSide(color: _outlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
        borderSide: const BorderSide(color: Colors.white),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
        foregroundColor: Colors.white,
        side: const BorderSide(color: _outlineColor),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF888888),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        hoverColor: Colors.white.withValues(alpha: 0.06),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _backgroundColor,
      indicatorColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: Colors.black),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF888888)),
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: const Color(0xFF888888),
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: Colors.white,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.black);
        }
        return const IconThemeData(color: Color(0xFF888888));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }
        return GoogleFonts.inter(
          color: const Color(0xFF888888),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: _surfaceContainer,
      side: const BorderSide(color: _outlineColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadiusButton),
      ),
      labelStyle: const TextStyle(color: Colors.white),
      selectedColor: Colors.white,
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      // 深色模式下 selectedColor 是白底，若未指定 checkmarkColor 會容易融掉。
      checkmarkColor: Colors.black,
    ),
    // 與 light theme 對齊：避免 SegmentedButton 在主題切換時因 style fallback 差異導致 tween 崩潰。
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Colors.white.withValues(alpha: 0.12),
        selectedForegroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF888888),
        side: const BorderSide(color: _outlineColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusButton),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(
          inherit: false,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    dividerColor: _outlineColor,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_kRadiusButton)),
      ),
    ),
    tooltipTheme: base.tooltipTheme,
    extensions: const <ThemeExtension<dynamic>>[
      DashboardAccentColors(
        success: _successColor,
        warning: _warningColor,
        danger: _criticalColor,
      ),
      DashboardHeatmapPalette(colors: _viridisColors),
    ],
  );
}

/// 提供儀表板常用的 success / warning / danger 強調色。
class DashboardAccentColors extends ThemeExtension<DashboardAccentColors> {
  const DashboardAccentColors({
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color success;
  final Color warning;
  final Color danger;

  /// 方便在 Widget tree 中取得擴充顏色的 helper。
  static DashboardAccentColors of(BuildContext context) =>
      context.extension<DashboardAccentColors>() ??
      const DashboardAccentColors(
        success: _successColor,
        warning: _warningColor,
        danger: _criticalColor,
      );

  @override
  ThemeExtension<DashboardAccentColors> copyWith({
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return DashboardAccentColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  // 線性插值
  @override
  ThemeExtension<DashboardAccentColors> lerp(
    ThemeExtension<DashboardAccentColors>? other,
    double t,
  ) {
    if (other is! DashboardAccentColors) {
      return this;
    }
    return DashboardAccentColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}

/// 提供 Heatmap 專用的調色盤（colormap）。
///
/// - 設計意圖：避免在各個圖表 widget 內硬編顏色常數，統一由 Theme 管控。
/// - 使用方式：`DashboardHeatmapPalette.of(context).colorAt(t)`，其中 t 為 0..1。
@immutable
class DashboardHeatmapPalette extends ThemeExtension<DashboardHeatmapPalette> {
  const DashboardHeatmapPalette({required this.colors});

  final List<Color> colors;

  static DashboardHeatmapPalette of(BuildContext context) =>
      context.extension<DashboardHeatmapPalette>() ??
      const DashboardHeatmapPalette(colors: _viridisColors);

  /// 以線性插值方式取得 0..1 的顏色。
  Color colorAt(double t) {
    if (colors.isEmpty) {
      return Colors.transparent;
    }
    if (colors.length == 1) {
      return colors.first;
    }
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (colors.length - 1);
    final i = scaled.floor();
    final frac = scaled - i;
    if (i >= colors.length - 1) {
      return colors.last;
    }
    return Color.lerp(colors[i], colors[i + 1], frac) ?? colors[i];
  }

  @override
  ThemeExtension<DashboardHeatmapPalette> copyWith({List<Color>? colors}) {
    return DashboardHeatmapPalette(colors: colors ?? this.colors);
  }

  @override
  ThemeExtension<DashboardHeatmapPalette> lerp(
    ThemeExtension<DashboardHeatmapPalette>? other,
    double t,
  ) {
    if (other is! DashboardHeatmapPalette) {
      return this;
    }
    if (colors.length != other.colors.length) {
      // 若兩者長度不同，直接回傳其中一方，避免不穩定的插值。
      return t < 0.5 ? this : other;
    }
    return DashboardHeatmapPalette(
      colors: List.generate(
        colors.length,
        (i) => Color.lerp(colors[i], other.colors[i], t) ?? colors[i],
      ),
    );
  }
}
