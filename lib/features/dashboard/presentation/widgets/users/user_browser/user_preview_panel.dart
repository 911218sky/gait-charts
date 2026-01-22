import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/cards/session_grid_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 使用者預覽面板，顯示使用者詳細資訊和 sessions。
class UserPreviewPanel extends StatelessWidget {
  const UserPreviewPanel({
    required this.selected,
    required this.preview,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onSelect,
    super.key,
  });

  final UserListItem? selected;
  final UserDetailResponse? preview;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onSelect;

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
  }

  Future<void> _copyToClipboard(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    DashboardToast.show(
      context,
      message: '已複製 $label',
      variant: DashboardToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    if (selected == null) {
      return _EmptyPreview(colors: colors);
    }

    final body = _buildBody(context, colors);

    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: body)),
        Divider(height: 1, color: colors.outlineVariant),
        _SelectFooter(
          name: selected!.name,
          colors: colors,
          onSelect: onSelect,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colors) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error != null) {
      return _PreviewError(
        error: error!,
        colors: colors,
        onRetry: onRetry,
      );
    }

    if (preview == null) {
      return const SizedBox.shrink();
    }

    return _PreviewContent(
      preview: preview!,
      colors: colors,
      formatDate: _formatDate,
      onCopyUserCode: (code) => _copyToClipboard(context, 'user_code', code),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '點選左側使用者以預覽',
              style: GoogleFonts.inter(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '提示：單擊預覽、雙擊直接選擇',
              style: GoogleFonts.inter(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({
    required this.error,
    required this.colors,
    required this.onRetry,
  });

  final String error;
  final ColorScheme colors;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 32),
            const SizedBox(height: 12),
            Text(
              '預覽載入失敗',
              style: GoogleFonts.inter(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.preview,
    required this.colors,
    required this.formatDate,
    required this.onCopyUserCode,
  });

  final UserDetailResponse preview;
  final ColorScheme colors;
  final String Function(DateTime) formatDate;
  final ValueChanged<String> onCopyUserCode;

  @override
  Widget build(BuildContext context) {
    final user = preview.user;
    final sessions = preview.sessions;
    final topSessions = sessions.take(5).toList(growable: false);

    final chips = _buildChips(user);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserHeader(
            user: user,
            colors: colors,
            onCopyUserCode: onCopyUserCode,
          ),
          const SizedBox(height: 14),
          if (chips.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: chips)
          else
            Text(
              '（此使用者尚未填寫更多基本資料）',
              style: GoogleFonts.inter(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'Sessions / Bag（${sessions.length}）',
            style: GoogleFonts.inter(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _SessionsList(
            sessions: sessions,
            topSessions: topSessions,
            colors: colors,
          ),
          const SizedBox(height: 8),
          Text(
            '建立：${formatDate(user.createdAt)}   更新：${formatDate(user.updatedAt)}',
            style: GoogleFonts.inter(
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChips(UserItem user) {
    final chips = <Widget>[];
    if ((user.sex ?? '').trim().isNotEmpty) {
      chips.add(Chip(label: Text('性別：${user.sex}')));
    }
    if (user.ageYears != null) {
      chips.add(Chip(label: Text('年齡：${user.ageYears}')));
    }
    if (user.assessmentDate != null) {
      chips.add(
        Chip(
          label: Text(
            '收案：${DateFormat('yyyy-MM-dd').format(user.assessmentDate!)}',
          ),
        ),
      );
    }
    for (final c in user.cohort) {
      chips.add(Chip(label: Text('族群：$c')));
    }
    return chips;
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.user,
    required this.colors,
    required this.onCopyUserCode,
  });

  final UserItem user;
  final ColorScheme colors;
  final ValueChanged<String> onCopyUserCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.surfaceContainerHigh,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(color: colors.onSurface),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.userCode,
                      style: GoogleFonts.inter(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppTooltip(
                    message: '複製 user_code',
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onCopyUserCode(user.userCode),
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionsList extends StatelessWidget {
  const _SessionsList({
    required this.sessions,
    required this.topSessions,
    required this.colors,
  });

  final List<UserSessionItem> sessions;
  final List<UserSessionItem> topSessions;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    if (topSessions.isEmpty) {
      return Text(
        '尚未綁定任何 session(bag)',
        style: GoogleFonts.inter(color: colors.onSurfaceVariant, fontSize: 12),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final desired = maxWidth >= 640 ? (maxWidth - 12) / 2 : maxWidth;
        final itemWidth = desired.clamp(220.0, maxWidth).toDouble();

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in topSessions)
              SizedBox(
                width: itemWidth,
                child: SessionGridCard.fromUserSession(item: s, onTap: null),
              ),
            if (sessions.length > topSessions.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '… 其餘 ${sessions.length - topSessions.length} 筆略',
                  style: GoogleFonts.inter(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SelectFooter extends StatelessWidget {
  const _SelectFooter({
    required this.name,
    required this.colors,
    required this.onSelect,
  });

  final String name;
  final ColorScheme colors;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('選擇'),
          ),
        ],
      ),
    );
  }
}
