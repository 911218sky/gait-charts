import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/features/apk/domain/models/apk_file.dart';
import 'package:gait_charts/features/apk/domain/utils/apk_download_uri_resolver.dart';

void main() {
  group('resolveApkDownloadUri', () {
    ApkFile file({
      required String path,
      required String name,
      required String url,
    }) {
      return ApkFile(
        path: path,
        name: name,
        sizeBytes: 1,
        modifiedAt: DateTime.utc(2025, 1, 1),
        url: url,
      );
    }

    test('absolute url: keep as-is', () {
      final base = Uri.parse('https://api.example.com/api/');
      final f = file(
        path: 'builds/app.apk',
        name: 'app.apk',
        url: 'https://cdn.example.com/apk/app.apk?x=1',
      );

      final got = resolveApkDownloadUri(base: base, file: f);
      expect(got.toString(), 'https://cdn.example.com/apk/app.apk?x=1');
    });

    test('root-relative url: resolve against base origin', () {
      final base = Uri.parse('https://api.example.com/api/');
      final f = file(
        path: 'builds/app.apk',
        name: 'app.apk',
        url: '/apk/app.apk',
      );

      final got = resolveApkDownloadUri(base: base, file: f);
      expect(got.toString(), 'https://api.example.com/apk/app.apk');
    });

    test('relative url: resolve relative to base path', () {
      final base = Uri.parse('https://api.example.com/api/v1/');
      final f = file(
        path: 'builds/app.apk',
        name: 'app.apk',
        url: 'apk/app.apk',
      );

      final got = resolveApkDownloadUri(base: base, file: f);
      expect(got.toString(), 'https://api.example.com/api/v1/apk/app.apk');
    });

    test('empty url: fallback to base path + /apk/{path}', () {
      final base = Uri.parse('https://api.example.com/api/v1/');
      final f = file(
        path: 'builds/app.apk',
        name: 'app.apk',
        url: '',
      );

      final got = resolveApkDownloadUri(base: base, file: f);
      expect(got.toString(), 'https://api.example.com/api/v1/apk/builds/app.apk');
    });
  });
}


