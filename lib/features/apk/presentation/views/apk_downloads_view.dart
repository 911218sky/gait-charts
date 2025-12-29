import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/apk/presentation/widgets/apk_downloads_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';

/// 登入後的安裝包下載頁面。
class ApkDownloadsView extends StatelessWidget {
  const ApkDownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ListView(
      padding: dashboardPagePadding(context),
      children: [
        Text(
          '應用程式下載',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '提供 Windows / macOS / Linux / Android 的安裝檔（或壓縮包）下載。',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const ApkDownloadsCard(
          maxVisibleItems: 999999,
          showViewAllAction: false,
          forceShowAllPlatforms: true,
        ),
      ],
    );
  }
}


