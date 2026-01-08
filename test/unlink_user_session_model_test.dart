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

    test('builds payload for sessionNames', () {
      final payload = const UnlinkUserSessionRequest(
        sessionNames: ['S_001'],
      ).toJson();
      expect(payload['session_names'], ['S_001']);
      expect(payload['unlink_all'], false);
    });

    test('builds payload for unlinkAll=true and forbids extra fields', () {
      final payload = const UnlinkUserSessionRequest(unlinkAll: true).toJson();
      expect(payload, {'unlink_all': true});

      expect(
        () => const UnlinkUserSessionRequest(
          unlinkAll: true,
          sessionNames: ['S_001'],
        ).toJson(),
        throwsArgumentError,
      );
    });
  });

  group('UnlinkUserSessionResponse.fromJson', () {
    test('parses batch mode with failed list', () {
      final response = UnlinkUserSessionResponse.fromJson(const {
        'user_code': 'u1',
        'mode': 'batch',
        'unlinked_sessions': 2,
        'failed': ['S_003'],
      });
      expect(response.userCode, 'u1');
      expect(response.mode, 'batch');
      expect(response.unlinkedSessions, 2);
      expect(response.failed, ['S_003']);
    });

    test('defaults missing fields gracefully', () {
      final response = UnlinkUserSessionResponse.fromJson(const {
        'user_code': 'u1',
        'mode': 'batch',
        'unlinked_sessions': 3,
        'failed': null,
      });
      expect(response.mode, 'batch');
      expect(response.unlinkedSessions, 3);
      expect(response.failed, isEmpty);
    });
  });
}


