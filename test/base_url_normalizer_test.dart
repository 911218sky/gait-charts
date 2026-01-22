import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/core/config/base_url.dart';

void main() {
  group('normalizeBaseUrl', () {
    test('移除尾端斜線並保留原本路徑', () {
      expect(
        normalizeBaseUrl('http://localhost:8100/v1/'),
        'http://localhost:8100/v1',
      );
      expect(
        normalizeBaseUrl('https://example.com/api///'),
        'https://example.com/api',
      );
    });

    test('不接受空字串或沒有 http/https scheme 的字串', () {
      expect(() => normalizeBaseUrl(''), throwsA(isA<FormatException>()));
      expect(() => normalizeBaseUrl('   '), throwsA(isA<FormatException>()));
      expect(() => normalizeBaseUrl('localhost:8100/v1'), throwsA(isA<FormatException>()));
      expect(() => normalizeBaseUrl('ftp://example.com'), throwsA(isA<FormatException>()));
    });
  });
}


