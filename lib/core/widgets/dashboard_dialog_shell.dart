import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// Dashboard 共用 Dialog 外殼：
/// - 統一深色 Vercel-ish 外觀（圓角/邊框/分隔線）
/// - 統一 Header/Body/Footer 的版面結構
///
/// 注意：此 widget 僅處理容器與版面，不處理業務邏輯。
class DashboardDialogShell extends StatelessWidget {
  const DashboardDialogShell({
    required this.header,
    required this.body,
    super.key,
    this.footer,
    this.constraints = const BoxConstraints(maxWidth: 720),
    this.insetPadding = const EdgeInsets.all(24),
    this.backgroundColor,
    this.expandBody = true,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;
  final BoxConstraints constraints;
  final EdgeInsets insetPadding;
  final Color? backgroundColor;
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final borderColor = colors.outlineVariant;

    return Dialog(
      backgroundColor: backgroundColor ?? colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: insetPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: constraints,
        child: Column(
          mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Divider(height: 1, color: borderColor),
            if (expandBody) Expanded(child: body) else body,
            if (footer != null) ...[
              Divider(height: 1, color: borderColor),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Dashboard 共用 Dialog Header：
/// - 左側標題/副標
/// - 右側 action（常見：refresh/close）
class DashboardDialogHeader extends StatelessWidget {
  const DashboardDialogHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 20),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final titleStyle = context.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: colors.onSurface,
    );
    final subtitleStyle = context.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: subtitleStyle),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}


