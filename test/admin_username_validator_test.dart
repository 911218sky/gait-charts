import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/features/admin/domain/validators/admin_username_validator.dart';

void main() {
  test('isValidAdminUsername 驗證規則', () {
    expect(isValidAdminUsername('abc'), isTrue);
    expect(isValidAdminUsername(' a_bc-1.2 '), isTrue);

    expect(isValidAdminUsername('ab'), isFalse);
    expect(isValidAdminUsername('a' * 65), isFalse);
    expect(isValidAdminUsername('ab c'), isFalse);
    expect(isValidAdminUsername('中文'), isFalse);
    expect(isValidAdminUsername('a@b'), isFalse);
  });
}


