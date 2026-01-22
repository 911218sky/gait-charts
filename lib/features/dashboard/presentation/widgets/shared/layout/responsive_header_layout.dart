import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 響應式 Header 佈局元件。
///
/// 根據螢幕寬度自動切換：
/// - 寬螢幕（>= 700px）：標題與操作按鈕水平排列
/// - 窄螢幕（< 700px）：標題與操作按鈕垂直堆疊
///
/// 使用方式：
/// ```dart
/// ResponsiveHeaderLayout(
///   title: 'Speed Heatmap',
///   description: '檢視每圈的速度分佈...',
///   actions: DashboardHeaderActions(activeSession: activeSession),
///   sessionInput: SessionAutocompleteField(...),
///   primaryAction: FilledButton.icon(...),
///   secondaryActions: [OutlinedButton.icon(...)],
///   settings: Wrap(...), // 可選，設定區塊
///   settingsTitle: '查詢設定', // 窄螢幕時 ExpansionTile 標題
///   settingsSubtitle: '投影 / 平滑 / 色階', // 窄螢幕時 ExpansionTile 副標題
/// )
/// ```
class ResponsiveHeaderLayout extends StatelessWidget {
  const ResponsiveHeaderLayout({
    required this.title,
    required this.description,
    this.actions,
    this.sessionInput,
    this.primaryAction,
    this.secondaryActions = const [],
    this.settings,
    this.settingsTitle,
    this.settingsSubtitle,
    super.key,
  });

  /// Header 標題。
  final String title;

  /// Header 描述文字。
  final String description;

  /// 右上角操作按鈕（如複製 session、開啟設定等）。
  final Widget? actions;

  /// Session 輸入欄位。
  final Widget? sessionInput;

  /// 主要操作按鈕（如「載入分析」）。
  final Widget? primaryAction;

  /// 次要操作按鈕列表（如「瀏覽 Sessions」）。
  final List<Widget> secondaryActions;

  /// 設定區塊（如投影平面、平滑視窗等）。
  final Widget? settings;

  /// 窄螢幕時 ExpansionTile 的標題。
  final String? settingsTitle;

  /// 窄螢幕時 ExpansionTile 的副標題。
  final String? settingsSubtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        return Container(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          decoration: BoxDecoration(
            color: context.scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: context.dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題區塊
              _buildTitleSection(context, isCompact, colors, textTheme),
              if (sessionInput != null) ...[
                const SizedBox(height: 20),
                // Session 輸入區塊
                _buildSessionInputSection(context, isCompact),
              ],
              if (settings != null) ...[
                const SizedBox(height: 18),
                // 設定區塊
                _buildSettingsSection(context, isCompact, colors, textTheme),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    bool isCompact,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    if (!isCompact) {
      // 寬螢幕：水平排列
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 16),
            actions!,
          ],
        ],
      );
    }

    // 窄螢幕：垂直堆疊
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (actions != null) ...[
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: actions!),
        ],
      ],
    );
  }

  Widget _buildSessionInputSection(BuildContext context, bool isCompact) {
    if (!isCompact) {
      // 寬螢幕：水平排列
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: sessionInput!),
          if (secondaryActions.isNotEmpty || primaryAction != null) ...[
            const SizedBox(width: 12),
            ...secondaryActions.map((action) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: action,
            )),
            if (primaryAction != null) primaryAction!,
          ],
        ],
      );
    }

    // 窄螢幕：垂直堆疊
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sessionInput!,
        if (secondaryActions.isNotEmpty || primaryAction != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              ...secondaryActions,
              if (primaryAction != null) primaryAction!,
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    bool isCompact,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    if (!isCompact) {
      return settings!;
    }

    // 窄螢幕：收納到 ExpansionTile
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 12),
      title: Text(
        settingsTitle ?? '設定',
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: settingsSubtitle != null
          ? Text(
              settingsSubtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          : null,
      children: [settings!],
    );
  }
}
