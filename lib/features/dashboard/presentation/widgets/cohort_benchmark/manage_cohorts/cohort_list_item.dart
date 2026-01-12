import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/initial_avatar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stat_badge.dart';

/// Cohort 列表項目（卡片風格）
class CohortListItem extends StatelessWidget {
  const CohortListItem({
    required this.cohortName,
    required this.userCount,
    required this.sessionCount,
    required this.lapCount,
    required this.version,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final String cohortName;
  final int userCount;
  final int sessionCount;
  final int lapCount;
  final int version;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accentColors = DashboardAccentColors.of(context);

    return Material(
      color: context.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colors.onSurface.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(context, colors),
              const SizedBox(width: 16),
              _buildContent(context, colors),
              const SizedBox(width: 12),
              _buildDeleteButton(accentColors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ColorScheme colors) {
    return InitialAvatar(
      text: cohortName,
      size: 44,
      borderRadius: 10,
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colors) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cohortName,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatBadge(
                icon: Icons.person_outline,
                label: '$userCount 人',
              ),
              StatBadge(
                icon: Icons.folder_outlined,
                label: '$sessionCount sessions',
              ),
              StatBadge(
                icon: Icons.directions_walk,
                label: '$lapCount laps',
              ),
              StatBadge(
                icon: Icons.tag,
                label: 'v$version',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(DashboardAccentColors accentColors) {
    return IconButton(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline_rounded, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: accentColors.danger.withValues(alpha: 0.8),
        backgroundColor: accentColors.danger.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(10),
        minimumSize: const Size(40, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tooltip: '刪除基準',
    );
  }
}
