import 'package:flutter_test/flutter_test.dart';

import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';

void main() {
  test('BagFileListResponse.fromJson parses items and pagination', () {
    final json = <String, dynamic>{
      'total': 2,
      'page': 1,
      'page_size': 50,
      'total_pages': 1,
      'items': [
        {
          'bag_id': 'a/1.bag',
          'name': '1.bag',
          'size_bytes': 123,
          'modified_at': '2025-12-26T10:20:30',
        },
        {
          'bag_id': '2.bag',
          'name': '2.bag',
          'size_bytes': '456',
          'modified_at': '2025-12-26T10:20:31Z',
        },
      ],
    };

    final res = BagFileListResponse.fromJson(json);
    expect(res.total, 2);
    expect(res.page, 1);
    expect(res.pageSize, 50);
    expect(res.totalPages, 1);
    expect(res.items.length, 2);
    expect(res.items[0].bagId, 'a/1.bag');
    expect(res.items[0].sizeBytes, 123);
    expect(res.items[1].sizeBytes, 456);
  });
}


