import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_profile_sections_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_sessions_card.dart';

/// 使用者詳情區：左側基本資料、右側 sessions/bag。
class UserDetailContent extends StatelessWidget {
  const UserDetailContent({
    required this.detail,
    required this.isBusy,
    required this.formatDate,
    required this.formatDateTime,
    required this.linkMode,
    required this.onLinkModeChanged,
    required this.sessionController,
    required this.bagHashController,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onLink,
    required this.onUnlink,
    required this.onUnlinkAll,
    required this.onActivateSession,
    super.key,
  });

  final UserDetailResponse detail;
  final bool isBusy;

  final String Function(DateTime? value) formatDate;
  final String Function(DateTime value) formatDateTime;

  final UserSessionLinkMode linkMode;
  final ValueChanged<UserSessionLinkMode> onLinkModeChanged;

  final TextEditingController sessionController;
  final TextEditingController bagHashController;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function(String label, String value) onCopy;
  final VoidCallback onLink;
  final Future<void> Function(UserSessionItem session) onUnlink;
  final Future<void> Function() onUnlinkAll;
  final ValueChanged<String> onActivateSession;

  @override
  Widget build(BuildContext context) {
    final isWide = context.isDesktopWide;

    final hint = detail.sessions.isEmpty
        ? Text(
            '此使用者目前尚未綁定任何 session(bag)。',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          )
        : null;

    final userCard = UserCard(
      user: detail.user,
      isBusy: isBusy,
      formatDate: formatDate,
      formatDateTime: formatDateTime,
      onEdit: onEdit,
      onDelete: onDelete,
      onCopy: onCopy,
    );

    final sessionsCard = UserSessionsCard(
      user: detail.user,
      sessions: detail.sessions,
      isBusy: isBusy,
      linkMode: linkMode,
      onLinkModeChanged: onLinkModeChanged,
      sessionController: sessionController,
      bagHashController: bagHashController,
      onLink: onLink,
      onUnlink: onUnlink,
      onUnlinkAll: onUnlinkAll,
      onCopy: onCopy,
      onActivateSession: onActivateSession,
    );
    final profileSectionsCard = UserProfileSectionsCard(user: detail.user);

    if (isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Padding(padding: const EdgeInsets.only(bottom: 12), child: hint),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    userCard,
                    const SizedBox(height: 24),
                    profileSectionsCard,
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: sessionsCard),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Padding(padding: const EdgeInsets.only(bottom: 12), child: hint),
        ],
        userCard,
        const SizedBox(height: 24),
        profileSectionsCard,
        const SizedBox(height: 24),
        sessionsCard,
      ],
    );
  }
}
