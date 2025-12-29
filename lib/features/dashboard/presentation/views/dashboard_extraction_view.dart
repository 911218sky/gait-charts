import 'package:flutter/material.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/extraction/extraction_panel.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';

/// 包裝資料提取流程的簡易 ListView。
class DashboardExtractionView extends StatelessWidget {
  const DashboardExtractionView({
    required this.sessionValue,
    required this.onCompleted,
    super.key,
  });

  final String sessionValue;
  final ValueChanged<ExtractResult> onCompleted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: dashboardPagePadding(context),
      children: [
        ExtractionPanel(
          suggestedSession: sessionValue,
          onCompleted: onCompleted,
        ),
      ],
    );
  }
}
