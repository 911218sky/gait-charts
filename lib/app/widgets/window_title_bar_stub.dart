import 'package:flutter/material.dart';

/// Web/手機：不顯示自訂標題列。
class AppWindowTitleBar extends StatelessWidget {
  const AppWindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}


