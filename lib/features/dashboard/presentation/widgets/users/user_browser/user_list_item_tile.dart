import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 使用者列表項目。
class UserListItemTile extends StatelessWidget {
  const UserListItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
    super.key,
  });

  final UserListItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      hoverColor: colors.onSurface.withValues(alpha: 0.05),
      child: Container(
        color: isSelected
            ? colors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.surfaceContainerHigh,
              child: Text(
                item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                style: TextStyle(color: colors.onSurface),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.userCode,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _formatDate(item.createdAt),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              size: 16,
              color: isSelected
                  ? DashboardAccentColors.of(context).success
                  : colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
