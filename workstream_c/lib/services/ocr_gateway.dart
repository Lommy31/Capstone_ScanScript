import 'dart:async';

import '../config/app_config.dart';
import '../models/ocr_result.dart';

abstract class OcrGateway {
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  });
}

class SafeOcrGateway implements OcrGateway {
  final OcrGateway inner;
  final AppConfig config;

  const SafeOcrGateway({required this.inner, required this.config});

  @override
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      // +500ms grace supaya timeout internal engine (status 'timeout') menang dulu.
      return await inner
          .recognize(imagePath: imagePath, imageId: imageId)
          .timeout(Duration(milliseconds: config.ocrTimeoutMs + 500));
    } on TimeoutException {
      return OcrResult.failed(
        imageId: imageId,
        status: 'timeout',
        processingMs: stopwatch.elapsedMilliseconds,
      );
    } catch (_) {
      return OcrResult.failed(
        imageId: imageId,
        status: 'error',
        processingMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}

class MockOcrGateway implements OcrGateway {
  const MockOcrGateway();

  @override
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    const samples = [
      ('Dear diary,', 0.93),
      ('today I went to the markat', 0.52),
      ('and bought fresh vegetables.', 0.88),
      ('Mom said the tomatoas were exspensive', 0.41),
      ('but we took them anyway.', 0.79),
    ];

    final lines = <OcrLine>[
      for (var i = 0; i < samples.length; i++)
        OcrLine(
          text: samples[i].$1,
          confidence: samples[i].$2,
          bbox: OcrBBox(x: 20, y: 30 + i * 48, width: 560, height: 40),
          lowConfidence: samples[i].$2 < 0.65,
        ),
    ];

    final avg =
        lines.fold<double>(0, (s, l) => s + (l.confidence ?? 0)) / lines.length;

    return OcrResult(
      imageId: imageId,
      engine: 'mlkit',
      fullText: lines.map((l) => l.text).join('\n'),
      lines: lines,
      avgConfidence: avg,
      processingMs: 900,
      status: 'ok',
    );
  }
}
