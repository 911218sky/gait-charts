import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 綁定 session(bag) 時的定位方式。
enum UserSessionLinkMode { sessionName, bagFilename }

/// 顯示使用者已綁定的 sessions/bag，並提供「新增綁定」的操作區。
class UserSessionsCard extends StatelessWidget {
  const UserSessionsCard({
    required this.user,
    required this.sessions,
    required this.isBusy,
    required this.linkMode,
    required this.onLinkModeChanged,
    required this.sessionController,
    required this.bagFilenameController,
    required this.onLink,
    required this.onUnlink,
    required this.onUnlinkAll,
    required this.onCopy,
    required this.onActivateSession,
    super.key,
    this.onPlayVideo,
  });

  final UserItem user;
  final List<UserSessionItem> sessions;
  final bool isBusy;

  final UserSessionLinkMode linkMode;
  final ValueChanged<UserSessionLinkMode> onLinkModeChanged;

  final TextEditingController sessionController;
  final TextEditingController bagFilenameController;

  final VoidCallback onLink;
  final Future<void> Function(UserSessionItem session) onUnlink;
  final Future<void> Function() onUnlinkAll;
  final Future<void> Function(String label, String value) onCopy;
  final ValueChanged<String> onActivateSession;
  final ValueChanged<UserSessionItem>? onPlayVideo;

  Future<void> _openSessionBrowser(BuildContext context) async {
    // 與分析頁共用的 Session Picker，維持單一樣式與邏輯。
    final selected = await SessionPickerDialog.show(
      context,
      // 綁定時排除「本使用者已綁定」的 sessions，避免重複選擇。
      excludeUserCode: user.userCode,
      // 在「使用者綁定」情境不需要 Users 分頁，避免多一層 user 預覽造成混淆。
      enableUserPicker: false,
    );
    if (selected == null || selected.isEmpty) {
      return;
    }
    sessionController.text = selected;
    if (linkMode != UserSessionLinkMode.sessionName) {
      onLinkModeChanged(UserSessionLinkMode.sessionName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sessions / Bag',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${sessions.length} 筆',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('以 session_name'),
                  selected: linkMode == UserSessionLinkMode.sessionName,
                  onSelected: isBusy
                      ? null
                      : (selected) {
                          if (selected) {
                            onLinkModeChanged(UserSessionLinkMode.sessionName);
                          }
                        },
                ),
                ChoiceChip(
                  label: const Text('以 bag_filename'),
                  selected: linkMode == UserSessionLinkMode.bagFilename,
                  onSelected: isBusy
                      ? null
                      : (selected) {
                          if (selected) {
                            onLinkModeChanged(UserSessionLinkMode.bagFilename);
                          }
                        },
                ),
                if (!isBusy)
                  OutlinedButton.icon(
                    onPressed: () => _openSessionBrowser(context),
                    icon: const Icon(Icons.search),
                    label: const Text('瀏覽 / 預覽 Sessions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                if (!isBusy && sessions.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: onUnlinkAll,
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('全部解除綁定'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent.danger,
                      backgroundColor: accent.danger.withValues(alpha: 0.10),
                      side: BorderSide(color: accent.danger),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (linkMode == UserSessionLinkMode.sessionName)
              SessionAutocompleteField(
                controller: sessionController,
                enabled: !isBusy,
                labelText: 'Session 名稱',
                hintText: '輸入 session_name 或按右側瀏覽/預覽',
                onSuggestionSelected: (_) {},
                onSubmitted: (_) => onLink(),
              )
            else
              TextField(
                controller: bagFilenameController,
                enabled: !isBusy,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onLink(),
                decoration: const InputDecoration(
                  labelText: 'Bag Filename',
                  hintText: '輸入 bag_filename（例如：1_1_607.bag）',
                  prefixIcon: Icon(Icons.insert_drive_file_outlined),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: isBusy ? null : onLink,
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('綁定到使用者'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '綁定後會把 session.user_code 設為 ${user.userCode}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.dividerColor),
                ),
                child: Text(
                  '尚未有任何 session(bag) 綁定到此使用者。',
                  style: context.textTheme.bodyMedium,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = sessions[index];
                  return _UserSessionTile(
                    item: item,
                    onCopy: onCopy,
                    onActivateSession: onActivateSession,
                    onUnlink: onUnlink,
                    isBusy: isBusy,
                    onPlayVideo: onPlayVideo != null ? () => onPlayVideo!(item) : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _UserSessionTile extends StatelessWidget {
  const _UserSessionTile({
    required this.item,
    required this.onCopy,
    required this.onActivateSession,
    required this.onUnlink,
    required this.isBusy,
    this.onPlayVideo,
  });

  final UserSessionItem item;
  final Future<void> Function(String label, String value) onCopy;
  final ValueChanged<String> onActivateSession;
  final Future<void> Function(UserSessionItem session) onUnlink;
  final bool isBusy;
  final VoidCallback? onPlayVideo;

  String _formatDate(DateTime d) {
    return DateFormat('yyyy/MM/dd HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: BoxDecoration(
                  color: context.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.description_outlined,
                  size: isMobile ? 18 : 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.sessionName,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 顯示 bag 檔案名稱
                    Text(
                      item.bagFilename,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // 桌面版：垂直排列的操作按鈕
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Column(
                  children: [
                    if (item.hasVideo && onPlayVideo != null) ...[
                      AppTooltip(
                        message: '播放影片',
                        child: IconButton(
                          onPressed: isBusy ? null : onPlayVideo,
                          icon: Icon(
                            Icons.play_circle_filled,
                            color: context.isDark ? Colors.white : colors.primary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: context.surfaceLight,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    AppTooltip(
                      message: '設為目前 Session',
                      child: IconButton(
                        onPressed: isBusy ? null : () => onActivateSession(item.sessionName),
                        icon: Icon(
                          Icons.play_circle_outline,
                          color: context.isDark ? Colors.white : colors.primary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: context.surfaceLight,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTooltip(
                      message: '解除綁定（保留 session）',
                      child: IconButton(
                        onPressed: isBusy ? null : () => onUnlink(item),
                        icon: Icon(
                          Icons.link_off_rounded,
                          size: 18,
                          color: accent.danger,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: accent.danger.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTooltip(
                      message: '複製 bag_path',
                      child: IconButton(
                        onPressed: isBusy ? null : () => onCopy('bag_path', item.bagPath),
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          // 手機版：水平排列的操作按鈕（放在底部）
          if (isMobile) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.hasVideo && onPlayVideo != null)
                  _MobileActionButton(
                    onPressed: isBusy ? null : onPlayVideo,
                    icon: Icons.play_circle_filled,
                    label: '播放',
                    color: context.isDark ? Colors.white : colors.primary,
                    backgroundColor: context.surfaceLight,
                  ),
                _MobileActionButton(
                  onPressed: isBusy ? null : () => onActivateSession(item.sessionName),
                  icon: Icons.play_circle_outline,
                  label: '設為目前',
                  color: context.isDark ? Colors.white : colors.primary,
                  backgroundColor: context.surfaceLight,
                ),
                _MobileActionButton(
                  onPressed: isBusy ? null : () => onUnlink(item),
                  icon: Icons.link_off_rounded,
                  label: '解除綁定',
                  color: accent.danger,
                  backgroundColor: accent.danger.withValues(alpha: 0.12),
                ),
                _MobileActionButton(
                  onPressed: isBusy ? null : () => onCopy('bag_path', item.bagPath),
                  icon: Icons.copy_rounded,
                  label: '複製路徑',
                  color: colors.onSurfaceVariant,
                  backgroundColor: context.surfaceLight,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 手機版操作按鈕：帶文字標籤，觸控區域至少 44px。
class _MobileActionButton extends StatelessWidget {
  const _MobileActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
