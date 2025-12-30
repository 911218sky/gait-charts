import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/async_error_view.dart';
import 'package:gait_charts/core/widgets/async_loading_view.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/user_autocomplete_field.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/layout/dashboard_page_padding.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/delete_user_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/unlink_all_user_sessions_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/unlink_user_session_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_browser_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_detail_content.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_profile_form_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_sessions_card.dart';
import 'package:intl/intl.dart';

/// 使用者管理：建立/編輯個案、以及把 session(bag) 綁到使用者。
class DashboardUsersView extends ConsumerStatefulWidget {
  const DashboardUsersView({super.key});

  @override
  ConsumerState<DashboardUsersView> createState() => _DashboardUsersViewState();
}

class _DashboardUsersViewState extends ConsumerState<DashboardUsersView> {
  late final TextEditingController _userNameController;
  late final TextEditingController _sessionNameController;
  late final TextEditingController _bagHashController;

  UserSessionLinkMode _linkMode = UserSessionLinkMode.sessionName;
  String? _selectedUserCode;
  bool _suppressNameListener = false;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _sessionNameController = TextEditingController();
    _bagHashController = TextEditingController();
    _userNameController.addListener(_handleUserNameChanged);
  }

  @override
  void dispose() {
    _userNameController
      ..removeListener(_handleUserNameChanged)
      ..dispose();
    _sessionNameController.dispose();
    _bagHashController.dispose();
    super.dispose();
  }

  void _handleUserNameChanged() {
    if (_suppressNameListener) {
      return;
    }
    // 使用者手動修改名稱時，清空已選的 user_code，避免「名稱/代碼不一致」。
    if (_selectedUserCode == null) {
      return;
    }
    setState(() {
      _selectedUserCode = null;
    });
  }

  void _setSelectedUser({required String userCode, required String name}) {
    setState(() {
      _selectedUserCode = userCode;
    });
    _suppressNameListener = true;
    _userNameController
      ..text = name
      ..selection = TextSelection.collapsed(offset: name.length);
    _suppressNameListener = false;
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUserCode = null;
    });
    _suppressNameListener = true;
    _userNameController.clear();
    _suppressNameListener = false;
  }

  void _toast(
    String message, {
    DashboardToastVariant variant = DashboardToastVariant.info,
  }) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return DateFormat('yyyy-MM-dd').format(value);
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  Future<void> _loadUser() async {
    final code = _selectedUserCode?.trim() ?? '';
    if (code.isNotEmpty) {
      await ref.read(userDetailProvider.notifier).load(code);
      return;
    }

    final keyword = _userNameController.text.trim();
    if (keyword.isEmpty) {
      _toast('請輸入使用者名稱，或點右側搜尋來瀏覽/預覽', variant: DashboardToastVariant.warning);
      return;
    }

    // 沒有對應的 user_code 時，改用瀏覽器讓使用者「挑選 + 預覽」後再載入。
    await _openUserBrowser(initialQuery: keyword);
  }

  Future<void> _openCreateDialog() async {
    final draft = await showDialog<UserProfileDraft>(
      context: context,
      builder: (context) => const UserProfileFormDialog(),
    );

    if (!mounted || draft == null) {
      return;
    }

    final created = await ref
        .read(userDetailProvider.notifier)
        .createUser(draft);
    if (!mounted) {
      return;
    }

    if (created == null) {
      _toast('建立使用者失敗', variant: DashboardToastVariant.danger);
      return;
    }

    _setSelectedUser(userCode: created.userCode, name: created.name);
    _toast(
      '已建立使用者：${created.name} (${created.userCode})',
      variant: DashboardToastVariant.success,
    );
  }

  Future<void> _openEditDialog(UserItem user) async {
    final draft = await showDialog<UserProfileDraft>(
      context: context,
      builder: (context) => UserProfileFormDialog.edit(user: user),
    );

    if (!mounted || draft == null) {
      return;
    }

    final notifier = ref.read(userDetailProvider.notifier);
    try {
      final updated = await notifier.updateCurrentUser(draft);
      if (!mounted) {
        return;
      }
      if (!updated) {
        _toast('沒有任何欄位變更', variant: DashboardToastVariant.info);
        return;
      }
      _toast('已更新使用者資料', variant: DashboardToastVariant.success);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _toast('更新失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _deleteCurrentUser() async {
    final detail = ref.read(userDetailProvider).detail;
    if (detail == null) {
      _toast('請先載入使用者', variant: DashboardToastVariant.warning);
      return;
    }

    final result = await DeleteUserDialog.show(
      context,
      userName: detail.user.name,
      userCode: detail.user.userCode,
    );
    if (!mounted || result == null) {
      return;
    }

    final notifier = ref.read(userDetailProvider.notifier);
    try {
      final response = await notifier.deleteCurrentUser(
        deleteSessions: result.deleteSessions,
      );
      if (!mounted) {
        return;
      }

      _clearSelectedUser();
      _toast(
        '已刪除使用者：${detail.user.name}（unlinked=${response.unlinkedSessions}, deleted=${response.deletedSessions}）',
        variant: DashboardToastVariant.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _toast('刪除失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _linkSession() async {
    final state = ref.read(userDetailProvider);
    if (!state.hasDetail) {
      _toast('請先載入使用者', variant: DashboardToastVariant.warning);
      return;
    }

    final sessionName = _sessionNameController.text.trim();
    final bagHash = _bagHashController.text.trim();

    if (_linkMode == UserSessionLinkMode.sessionName && sessionName.isEmpty) {
      _toast('請輸入 session_name', variant: DashboardToastVariant.warning);
      return;
    }

    if (_linkMode == UserSessionLinkMode.bagHash && bagHash.isEmpty) {
      _toast('請輸入 bag_hash', variant: DashboardToastVariant.warning);
      return;
    }

    final notifier = ref.read(userDetailProvider.notifier);
    try {
      await notifier.linkSessionToCurrentUser(
        sessionName: _linkMode == UserSessionLinkMode.sessionName
            ? sessionName
            : null,
        bagHash: _linkMode == UserSessionLinkMode.bagHash ? bagHash : null,
      );
      if (!mounted) {
        return;
      }
      _sessionNameController.clear();
      _bagHashController.clear();
      _toast('已綁定 session 至使用者', variant: DashboardToastVariant.success);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _toast('綁定失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _unlinkSession(UserSessionItem session) async {
    final state = ref.read(userDetailProvider);
    final detail = state.detail;
    if (detail == null) {
      _toast('請先載入使用者', variant: DashboardToastVariant.warning);
      return;
    }

    final confirmed = await UnlinkUserSessionDialog.show(
      context,
      userName: detail.user.name,
      sessionName: session.sessionName,
      bagPath: session.bagPath,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final notifier = ref.read(userDetailProvider.notifier);
    try {
      final response = await notifier.unlinkSessionFromCurrentUser(
        sessionName: session.sessionName,
      );
      if (!mounted) {
        return;
      }
      final count = response.unlinkedSessions;
      _toast(
        count <= 1
            ? '已解除綁定：${session.sessionName}'
            : '已解除綁定 $count 筆 sessions',
        variant: DashboardToastVariant.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _toast('解除綁定失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _unlinkAllSessions() async {
    final state = ref.read(userDetailProvider);
    final detail = state.detail;
    if (detail == null) {
      _toast('請先載入使用者', variant: DashboardToastVariant.warning);
      return;
    }

    final count = detail.sessions.length;
    if (count <= 0) {
      _toast('此使用者沒有可解除的 sessions', variant: DashboardToastVariant.info);
      return;
    }

    final confirmed = await UnlinkAllUserSessionsDialog.show(
      context,
      userName: detail.user.name,
      userCode: detail.user.userCode,
      sessionCount: count,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final notifier = ref.read(userDetailProvider.notifier);
    try {
      final response = await notifier.unlinkSessionFromCurrentUser(
        unlinkAll: true,
      );
      if (!mounted) {
        return;
      }
      _toast(
        '已解除綁定 ${response.unlinkedSessions} 筆 sessions',
        variant: DashboardToastVariant.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _toast('解除綁定失敗：$error', variant: DashboardToastVariant.danger);
    }
  }

  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    _toast('已複製 $label', variant: DashboardToastVariant.success);
  }

  void _setActiveSession(String sessionName) {
    final name = sessionName.trim();
    if (name.isEmpty) {
      return;
    }
    ref.read(activeSessionProvider.notifier).setSession(name);
    ref.invalidate(stageDurationsProvider);
    _toast('已切換目前 Session：$name', variant: DashboardToastVariant.success);
  }

  Future<void> _openUserBrowser({String? initialQuery}) async {
    final result = await showDialog<UserListItem>(
      context: context,
      builder: (context) => UserBrowserDialog(initialQuery: initialQuery),
    );

    if (result != null && mounted) {
      _setSelectedUser(userCode: result.userCode, name: result.name);
      await ref.read(userDetailProvider.notifier).load(result.userCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userDetailProvider);
    final textTheme = context.textTheme;

    return ListView(
      padding: dashboardPagePadding(context),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '使用者 / 個案管理',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '建立使用者、更新基本資料，並將 session(bag) 綁定到指定個案。',
                            style: textTheme.bodyMedium?.copyWith(
                              color: textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: userState.isBusy ? null : _openCreateDialog,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('新增使用者'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : 340.0;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: maxWidth.clamp(0.0, 340.0),
                          child: UserAutocompleteField(
                            controller: _userNameController,
                            labelText: '使用者名稱',
                            hintText: '輸入姓名後按 Enter，或用右側按鈕瀏覽/預覽',
                            helperText: _selectedUserCode == null
                                ? '提示：輸入可縮小範圍；點選下拉建議可直接載入。'
                                : 'user_code：$_selectedUserCode',
                            maxSuggestions: 10,
                            onSubmitted: (_) => _loadUser(),
                            onSuggestionSelected: (item) async {
                              _setSelectedUser(
                                userCode: item.userCode,
                                name: item.name,
                              );
                              await ref
                                  .read(userDetailProvider.notifier)
                                  .load(item.userCode);
                            },
                          ),
                        ),
                    OutlinedButton.icon(
                      onPressed: userState.isBusy
                          ? null
                          : () => _openUserBrowser(
                              initialQuery: _userNameController.text.trim(),
                            ),
                      icon: const Icon(Icons.search),
                      label: const Text('瀏覽 / 預覽使用者'),
                    ),
                    FilledButton.icon(
                      onPressed: userState.isBusy ? null : _loadUser,
                      icon: userState.isInitialLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('載入'),
                    ),
                    OutlinedButton.icon(
                      onPressed: userState.isBusy
                          ? null
                          : () {
                              _clearSelectedUser();
                              ref.read(userDetailProvider.notifier).reset();
                            },
                      icon: const Icon(Icons.clear),
                      label: const Text('清除'),
                    ),
                    if (userState.hasDetail)
                      OutlinedButton.icon(
                        onPressed: userState.isBusy
                            ? null
                            : () => ref
                                  .read(userDetailProvider.notifier)
                                  .refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新整理'),
                      ),
                    if (userState.isSaving)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '更新中…',
                            style: textTheme.bodySmall?.copyWith(
                              color: textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (userState.isInitialLoading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: AsyncLoadingView(label: '載入使用者資料中…'),
            ),
          )
        else if (userState.error != null && !userState.hasDetail)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: AsyncErrorView(
                error: userState.error!,
                onRetry: _loadUser,
              ),
            ),
          )
        else if (!userState.hasDetail)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '尚未選擇使用者',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '你可以先輸入 user_code 載入既有使用者，或點擊上方「新增使用者」建立新個案。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          UserDetailContent(
            detail: userState.detail!,
            isBusy: userState.isBusy,
            formatDate: _formatDate,
            formatDateTime: _formatDateTime,
            linkMode: _linkMode,
            onLinkModeChanged: (mode) => setState(() => _linkMode = mode),
            sessionController: _sessionNameController,
            bagHashController: _bagHashController,
            onEdit: () => _openEditDialog(userState.detail!.user),
            onDelete: _deleteCurrentUser,
            onCopy: _copyToClipboard,
            onLink: _linkSession,
            onUnlink: _unlinkSession,
            onUnlinkAll: _unlinkAllSessions,
            onActivateSession: _setActiveSession,
          ),
      ],
    );
  }
}
