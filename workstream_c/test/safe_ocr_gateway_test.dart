import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workstream_c/config/app_config.dart';
import 'package:workstream_c/models/ocr_result.dart';
import 'package:workstream_c/services/ocr_gateway.dart';

class _Hangs implements OcrGateway {
  @override
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  }) => Completer<OcrResult>().future; // tidak pernah selesai
}

class _Throws implements OcrGateway {
  @override
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  }) async => throw StateError('boom');
}

void main() {
  const config = AppConfig(
    lowConfidenceThreshold: 0.65,
    ocrTimeoutMs: 50, // kecil supaya test cepat
    maxSkewCorrectionDeg: 15,
  );

  test(
    'engine yang hang menghasilkan status timeout, bukan menggantung',
    () async {
      final gw = SafeOcrGateway(inner: _Hangs(), config: config);
      final r = await gw.recognize(imagePath: 'x', imageId: '1');
      expect(r.status, 'timeout');
      expect(r.fullText, isEmpty);
    },
  );

  test('engine yang throw menghasilkan status error, bukan crash', () async {
    final gw = SafeOcrGateway(inner: _Throws(), config: config);
    final r = await gw.recognize(imagePath: 'x', imageId: '1');
    expect(r.status, 'error');
  });

  test('mock gateway mengembalikan hasil ok dengan confidence', () async {
    final gw = SafeOcrGateway(
      inner: const MockOcrGateway(),
      config: const AppConfig(
        lowConfidenceThreshold: 0.65,
        ocrTimeoutMs: 4000,
        maxSkewCorrectionDeg: 15,
      ),
    );
    final r = await gw.recognize(imagePath: 'x', imageId: '1');
    expect(r.isOk, isTrue);
    expect(r.lines, isNotEmpty);
    expect(r.avgConfidence!, greaterThan(0));
  });
}
