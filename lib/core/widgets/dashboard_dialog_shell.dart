import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// Dashboard 共用 Dialog 外殼。
///
/// 提供統一的深色 Vercel 風格外觀與 Header/Body/Footer 版面結構。
/// 手機版會自動調整為接近全螢幕的佈局。
class DashboardDialogShell extends StatelessWidget {
  const DashboardDialogShell({
    required this.header,
    required this.body,
    super.key,
    this.footer,
    this.constraints = const BoxConstraints(maxWidth: 720),
    this.insetPadding,
    this.backgroundColor,
    this.expandBody = true,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;
  final BoxConstraints constraints;
  /// 對話框與螢幕邊緣的間距。若為 null，會根據螢幕大小自動調整。
  final EdgeInsets? insetPadding;
  final Color? backgroundColor;
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final borderColor = colors.outlineVariant;
    final isMobile = context.isMobile;

    // 手機版：縮小邊距，讓對話框更接近全螢幕
    final effectiveInsetPadding = insetPadding ??
        (isMobile
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
            : const EdgeInsets.all(24));

    // 手機版：移除 maxWidth 限制
    final effectiveConstraints = isMobile
        ? BoxConstraints(
            maxWidth: double.infinity,
            maxHeight: constraints.maxHeight,
          )
        : constraints;

    return Dialog(
      backgroundColor: backgroundColor ?? colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: effectiveInsetPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: effectiveConstraints,
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

/// Dashboard 共用 Dialog Header。
///
/// 左側顯示標題/副標，右側放置 action（如 refresh/close）。
/// 手機版會自動縮小 padding。
class DashboardDialogHeader extends StatelessWidget {
  const DashboardDialogHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  /// Header 內邊距。若為 null，會根據螢幕大小自動調整。
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isMobile = context.isMobile;
    
    final effectivePadding = padding ??
        (isMobile
            ? const EdgeInsets.fromLTRB(16, 16, 16, 16)
            : const EdgeInsets.fromLTRB(24, 20, 24, 20));
    
    final titleStyle = context.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: colors.onSurface,
      fontSize: isMobile ? 18 : null,
    );
    final subtitleStyle = context.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Padding(
      padding: effectivePadding,
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


