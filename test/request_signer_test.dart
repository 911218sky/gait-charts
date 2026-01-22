import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gait_charts/core/network/signing/request_signer.dart';

void main() {
  test('canonicalString 需符合後端規格（含 query）', () {
    final signer = RequestSigner();

    final msg = signer.canonicalString(
      method: 'post',
      path: '/v1/sessions',
      query: 'a=1&b=2',
      nonce: 'nonce-123',
      timestamp: '1700000000',
      bodySha256: 'deadbeef',
      version: 'v1',
    );

    expect(
      msg,
      'v1\nPOST\n/v1/sessions?a=1&b=2\nnonce-123\n1700000000\ndeadbeef',
    );
  });

  test('signatureHex 應等於 HMAC-SHA256(hex) 的結果', () {
    final signer = RequestSigner();

    const secret = 'secret';
    const body = {'k': 'v'};
    final bodySha = signer.bodySha256Hex(body);

    final msg = signer.canonicalString(
      method: 'POST',
      path: '/v1/hello',
      query: '',
      nonce: 'abc',
      timestamp: '1700000000',
      bodySha256: bodySha,
      version: 'v1',
    );

    final actual = signer.signatureHex(
      secret: Uint8List.fromList(utf8.encode(secret)),
      message: msg,
    );

    final expected = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(msg))
        .bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    expect(actual, expected);
  });
}


