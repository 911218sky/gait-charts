import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 一個通用的 Session 卡片元件，用於 Grid 顯示。
///
/// 支援 [RealsenseSessionItem] (Session Browser) 與 [UserSessionItem] (User Preview)。
class SessionGridCard extends StatelessWidget {
  const SessionGridCard({
    required this.sessionName,
    required this.bagPath,
    required this.bagFilename,
    required this.date,
    super.key,
    this.hasVideo = false,
    this.onTap,
    this.onPlayVideo,
  });

  factory SessionGridCard.fromRealsenseSession({
    required RealsenseSessionItem item,
    VoidCallback? onTap,
    VoidCallback? onPlayVideo,
  }) {
    return SessionGridCard(
      sessionName: item.sessionName,
      bagPath: item.bagPath,
      bagFilename: item.bagFilename,
      date: item.createdAt,
      hasVideo: item.hasVideo,
      onTap: onTap,
      onPlayVideo: onPlayVideo,
    );
  }

  factory SessionGridCard.fromUserSession({
    required UserSessionItem item,
    VoidCallback? onTap,
    VoidCallback? onPlayVideo,
  }) {
    return SessionGridCard(
      sessionName: item.sessionName,
      bagPath: item.bagPath,
      bagFilename: item.bagFilename,
      date: item.createdAt,
      hasVideo: item.hasVideo,
      onTap: onTap,
      onPlayVideo: onPlayVideo,
    );
  }

  final String sessionName;
  final String bagPath;
  /// BAG 檔案名稱。
  final String bagFilename;
  final DateTime? date;

  /// 是否有影片可播放。
  final bool hasVideo;
  final VoidCallback? onTap;
  
  /// 點擊播放影片的 callback。
  final VoidCallback? onPlayVideo;

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('yyyy/MM/dd HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

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
        child: Stack(
          children: [
            // 主要內容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    sessionName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Bag 檔案名稱
                  Text(
                    bagFilename,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Date
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // 右上角影片緞帶標示
            if (hasVideo)
              Positioned(
                top: 0,
                right: 0,
                child: _VideoRibbon(colors: colors)
              )
          ],
        ),
      ),
    );
  }
}

/// 右上角的影片緞帶標示。
class _VideoRibbon extends StatelessWidget {
  const _VideoRibbon({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          size: 18,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}
