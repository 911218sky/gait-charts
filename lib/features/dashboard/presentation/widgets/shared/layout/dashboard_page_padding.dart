import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// Dashboard 各頁面共用的 responsive padding。
///
/// - 桌面/網頁：維持既有 24px 左右留白
/// - 手機：縮到 16px，避免內容區太窄
EdgeInsets dashboardPagePadding(BuildContext context) {
  final horizontal = context.isMobile ? 16.0 : 24.0;
  return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32);
}


