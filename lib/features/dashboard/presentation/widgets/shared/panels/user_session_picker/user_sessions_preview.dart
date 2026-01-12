import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/panels/user_session_picker/simple_session_card.dart';

/// 使用者 sessions 預覽面板。
class UserSessionsPreview extends StatelessWidget {
  const UserSessionsPreview({
    required this.detail,
    required this.onSelectSession,
    required this.onDeleteUser,
    super.key,
  });

  final UserDetailResponse detail;
  final ValueChanged<String> onSelectSession;
  final VoidCallback? onDeleteUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final sessions = detail.sessions;
    final cohort = detail.user.cohort;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                detail.user.name,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                '${sessions.length} sessions',
                style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '刪除使用者',
              onPressed: onDeleteUser,
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(foregroundColor: DashboardAccentColors.of(context).danger),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          detail.user.userCode,
          style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, fontFamily: 'monospace'),
        ),
        if (cohort.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final c in cohort) Chip(label: Text(c))]),
        ],
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                '此使用者尚未綁定任何 session(bag)。',
                style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 160,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final item = sessions[index];
                return SimpleSessionCard(
                  sessionName: item.sessionName,
                  bagPath: item.bagPath,
                  bagFilename: item.bagFilename,
                  createdAt: item.createdAt,
                  onTap: () => onSelectSession(item.sessionName),
                );
              },
            ),
          ),
      ],
    );
  }
}
