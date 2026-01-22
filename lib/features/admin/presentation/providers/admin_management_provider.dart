import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/admin/data/admin_repository.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';

class AdminManagementState {
  const AdminManagementState({
    required this.list,
    this.latestInvitation,
  });

  final AdminListResponse list;
  final InvitationCode? latestInvitation;

  AdminManagementState copyWith({
    AdminListResponse? list,
    InvitationCode? latestInvitation,
  }) {
    return AdminManagementState(
      list: list ?? this.list,
      latestInvitation: latestInvitation ?? this.latestInvitation,
    );
  }
}

class AdminManagementNotifier
    extends AsyncNotifier<AdminManagementState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  String _requireToken() {
    final token = ref.read(adminTokenProvider);
    if (token == null || token.isEmpty) {
      throw ApiException(message: '尚未登入管理員，請重新登入');
    }
    return token;
  }

  @override
  Future<AdminManagementState> build() async {
    final token = _requireToken();
    final list = await _repo.listAdmins(token: token, page: 1);
    return AdminManagementState(list: list);
  }

  Future<void> refresh({int page = 1}) async {
    final prevInvitation = state.asData?.value.latestInvitation;
    // Keep previous list while loading if desired, or show loading.
    // Here we show loading by setting state to AsyncLoading.
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final token = _requireToken();
      final list = await _repo.listAdmins(token: token, page: page);
      return AdminManagementState(
        list: list,
        latestInvitation: prevInvitation,
      );
    });
  }

  Future<InvitationCode> createInvitation({required int expiresInHours}) async {
    final token = _requireToken();
    final invitation = await _repo.createInvitation(
      token: token,
      expiresInHours: expiresInHours,
    );
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(latestInvitation: invitation));
    }
    return invitation;
  }

  Future<DeleteAdminResult> deleteAdmin(String adminCode) async {
    final token = _requireToken();
    final result = await _repo.deleteAdmin(
      token: token,
      adminCode: adminCode,
    );
    // 刪除成功則重新整理列表
    if (result.deleted) {
      await refresh();
    }
    return result;
  }
}

final adminManagementProvider =
    AsyncNotifierProvider<AdminManagementNotifier, AdminManagementState>(
  AdminManagementNotifier.new,
);

