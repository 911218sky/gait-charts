import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:intl/intl.dart';

import 'video_ribbon.dart';

/// 單一 session 的卡片與 hover 效果。
class SessionCard extends StatefulWidget {
  const SessionCard({
    required this.item,
    required this.backgroundColor,
    required this.borderColor,
    required this.onSelect,
    required this.onDelete,
    required this.isDeleting,
    super.key,
  });

  final RealsenseSessionItem item;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    final createdAt = widget.item.createdAt != null
        ? DateFormat('yyyy/MM/dd HH:mm')
            .format(widget.item.createdAt!.toLocal())
        : 'Unknown Date';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(
                  color: _isHovered ? colors.primary : widget.borderColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, colors),
                  const SizedBox(height: 12),
                  Text(
                    widget.item.sessionName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    widget.item.bagFilename,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAt,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.item.hasVideo)
              Positioned(
                top: 0,
                right: 0,
                child: VideoRibbon(colors: colors),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : colors.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.analytics_outlined,
            size: 16,
            color: context.isDark ? Colors.white : colors.primary,
          ),
        ),
        const Spacer(),
        if (widget.isDeleting)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_isHovered) ...[
          AppTooltip(
            message: '刪除 Session',
            child: IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: colors.onSurface,
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 16, color: colors.onSurface),
        ],
      ],
    );
  }
}
