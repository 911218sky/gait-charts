import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

void main() {
  group('UnlinkUserSessionRequest.toJson', () {
    test('throws when no target and unlinkAll=false', () {
      expect(
        () => const UnlinkUserSessionRequest().toJson(),
        throwsArgumentError,
      );
    });

    test('builds payload for sessionName', () {
      final payload = const UnlinkUserSessionRequest(
        sessionName: 'S_001',
      ).toJson();
      expect(payload['session_name'], 'S_001');
      expect(payload['unlink_all'], false);
    });

    test('builds payload for unlinkAll=true and forbids extra fields', () {
      final payload = const UnlinkUserSessionRequest(unlinkAll: true).toJson();
      expect(payload, {'unlink_all': true});

      expect(
        () => const UnlinkUserSessionRequest(
          unlinkAll: true,
          sessionName: 'S_001',
        ).toJson(),
        throwsArgumentError,
      );
    });
  });

  group('UnlinkUserSessionResponse.fromJson', () {
    test('parses single mode with session', () {
      final response = UnlinkUserSessionResponse.fromJson({
        'user_code': 'u1',
        'mode': 'single',
        'unlinked_sessions': 1,
        'session': {
          'session_name': 'S_001',
          'user_code': null,
          'npy_path': 'x.npy',
          'bag_path': 'x.bag',
          'bag_hash': 'h',
          'created_at': '2025-01-01T00:00:00Z',
          'updated_at': '2025-01-01T00:00:00Z',
        },
      });
      expect(response.userCode, 'u1');
      expect(response.mode, 'single');
      expect(response.unlinkedSessions, 1);
      expect(response.session?.sessionName, 'S_001');
    });

    test('parses all mode without session', () {
      final response = UnlinkUserSessionResponse.fromJson({
        'user_code': 'u1',
        'mode': 'all',
        'unlinked_sessions': 3,
        'session': null,
      });
      expect(response.mode, 'all');
      expect(response.unlinkedSessions, 3);
      expect(response.session, isNull);
    });
  });
}


