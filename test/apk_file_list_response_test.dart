import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/apk/domain/models/apk_file_list.dart';

void main() {
  test('ApkFileListResponse.fromJson: parses base_dir + files', () {
    final json = <String, dynamic>{
      'base_dir': '/app/data/apk',
      'files': [
        {
          'path': 'releases/app-release.apk',
          'name': 'app-release.apk',
          'size_bytes': 12345678,
          'mtime': 1730000000,
          'url': 'http://localhost:8000/apk/releases/app-release.apk',
        },
      ],
    };

    final res = ApkFileListResponse.fromJson(json);
    expect(res.baseDir, '/app/data/apk');
    expect(res.files.length, 1);

    final file = res.files.first;
    expect(file.path, 'releases/app-release.apk');
    expect(file.name, 'app-release.apk');
    expect(file.sizeBytes, 12345678);
    expect(file.url, 'http://localhost:8000/apk/releases/app-release.apk');
    // mtime 是 unix seconds (UTC)
    expect(file.modifiedAt.isUtc, true);
    expect(file.modifiedAt.millisecondsSinceEpoch, 1730000000 * 1000);
  });
}


