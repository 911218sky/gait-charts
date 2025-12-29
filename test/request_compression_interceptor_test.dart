import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/network/interceptors/request_compression_interceptor.dart';

void main() {
  test('啟用時：JSON body 會 gzip 成 bytes，並以 application/octet-stream 送出', () async {
    final config = AppConfig(
      baseUrl: 'http://example.com',
      requestCompressionEnabled: true,
    );
    final interceptor = RequestCompressionInterceptor(config: config);

    final options = RequestOptions(
      path: '/v1/test',
      method: 'POST',
      baseUrl: 'http://example.com',
      data: {'hello': 'world'},
    );

    RequestOptions? captured;
    final handler = _CapturingRequestHandler((o) => captured = o);
    interceptor.onRequest(options, handler);

    expect(captured, isNotNull);
    expect(captured!.headers[Headers.contentTypeHeader], 'application/octet-stream');
    expect(
      captured!.headers[RequestCompressionInterceptor.kHeaderPayloadEncoding],
      'gzip',
    );
    expect(
      captured!.headers[RequestCompressionInterceptor.kHeaderPayloadContentType],
      'application/json',
    );
    expect(captured!.data, isA<Uint8List>());

    final gzBytes = captured!.data as Uint8List;
    final decoded = GZipDecoder().decodeBytes(gzBytes);
    final jsonText = utf8.decode(decoded);
    expect(jsonDecode(jsonText), {'hello': 'world'});
  });
}

class _CapturingRequestHandler extends RequestInterceptorHandler {
  _CapturingRequestHandler(this._onNext);

  final void Function(RequestOptions options) _onNext;

  @override
  void next(RequestOptions options) {
    _onNext(options);
  }
}


