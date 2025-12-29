import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 綁定 session(bag) 時的定位方式。
enum UserSessionLinkMode { sessionName, bagHash }

/// 顯示使用者已綁定的 sessions/bag，並提供「新增綁定」的操作區。
class UserSessionsCard extends StatelessWidget {
  const UserSessionsCard({
    required this.user,
    required this.sessions,
    required this.isBusy,
    required this.linkMode,
    required this.onLinkModeChanged,
    required this.sessionController,
    required this.bagHashController,
    required this.onLink,
    required this.onUnlink,
    required this.onUnlinkAll,
    required this.onCopy,
    required this.onActivateSession,
    super.key,
  });

  final UserItem user;
  final List<UserSessionItem> sessions;
  final bool isBusy;

  final UserSessionLinkMode linkMode;
  final ValueChanged<UserSessionLinkMode> onLinkModeChanged;

  final TextEditingController sessionController;
  final TextEditingController bagHashController;

  final VoidCallback onLink;
  final Future<void> Function(UserSessionItem session) onUnlink;
  final Future<void> Function() onUnlinkAll;
  final Future<void> Function(String label, String value) onCopy;
  final ValueChanged<String> onActivateSession;

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
                  label: const Text('以 bag_hash'),
                  selected: linkMode == UserSessionLinkMode.bagHash,
                  onSelected: isBusy
                      ? null
                      : (selected) {
                          if (selected) {
                            onLinkModeChanged(UserSessionLinkMode.bagHash);
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
                controller: bagHashController,
                enabled: !isBusy,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onLink(),
                decoration: const InputDecoration(
                  labelText: 'Bag Hash',
                  hintText: '輸入 bag_hash',
                  prefixIcon: Icon(Icons.tag_outlined),
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
  });

  final UserSessionItem item;
  final Future<void> Function(String label, String value) onCopy;
  final ValueChanged<String> onActivateSession;
  final Future<void> Function(UserSessionItem session) onUnlink;
  final bool isBusy;

  String _formatDate(DateTime d) {
    return DateFormat('yyyy/MM/dd HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final accent = DashboardAccentColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : colors.surfaceContainerHighest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.description_outlined,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.sessionName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.bagPath,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((item.bagHash ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.tag, size: 12, color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.bagHash!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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
          const SizedBox(width: 12),
          // Actions
          Column(
            children: [
              AppTooltip(
                message: '設為目前 Session',
                child: IconButton(
                  onPressed: isBusy ? null : () => onActivateSession(item.sessionName),
                  icon: Icon(
                    Icons.play_circle_outline,
                    color: isDark ? Colors.white : colors.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF222222) : colors.surfaceContainer,
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
      ),
    );
  }
}
