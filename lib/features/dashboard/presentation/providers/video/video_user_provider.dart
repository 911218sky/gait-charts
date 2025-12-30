import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/services/users/users_api_service.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 透過 BAG 檔案名稱查詢綁定的使用者。
///
/// 使用 family provider，以 bagFilename 作為參數。
/// 回傳 [FindUserByBagResponse]，包含使用者資訊和相關 sessions。
final findUserByBagProvider = FutureProvider.family
    .autoDispose<FindUserByBagResponse?, String?>((ref, bagFilename) async {
  if (bagFilename == null || bagFilename.trim().isEmpty) {
    return null;
  }
  final api = ref.watch(usersApiServiceProvider);
  final request = FindUserByBagRequest(bagFilename: bagFilename);
  return api.findUserByBag(request: request);
});
