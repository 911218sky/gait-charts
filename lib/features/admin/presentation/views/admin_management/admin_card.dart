import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:intl/intl.dart';

/// 管理員卡片元件。
///
/// 顯示單一管理員的資訊，包含帳號、建立日期等。
/// 若為目前登入者會顯示 "YOU" 標籤，可刪除的管理員會顯示刪除按鈕。
class AdminCard extends StatelessWidget {
  const AdminCard({
    required this.item,
    required this.isMe,
    required this.canDelete,
    required this.onDelete,
    super.key,
  });

  final AdminListItem item;
  /// 是否為目前登入的管理員
  final bool isMe;
  /// 是否可以刪除（不能刪自己，也不能刪 root）
  final bool canDelete;
  final VoidCallback onDelete;

  String _formatDate(DateTime date) {
    // 後端回傳 UTC，轉成本地時間方便閱讀
    return DateFormat('yyyy/MM/dd').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, textTheme),
          const Spacer(),
          _buildUserInfo(colors, textTheme),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 12),
          _buildFooter(colors, textTheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.admin_panel_settings_outlined,
            color: colors.primary,
            size: 28,
          ),
        ),
        const Spacer(),
        if (isMe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'YOU',
              style: textTheme.labelSmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (canDelete)
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: colors.error),
            tooltip: '刪除',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        else if (!isMe)
          Icon(Icons.lock_outline, size: 20, color: colors.outline),
      ],
    );
  }

  Widget _buildUserInfo(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.username,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          item.adminCode,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colors, TextTheme textTheme) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(item.createdAt),
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (item.invitedByCode != null) ...[
          const Spacer(),
          Icon(Icons.link, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Invited',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
