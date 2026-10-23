import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ocr_result.dart';
import 'ocr_engine.dart';

/// Engine ML Kit (Workstream B), disesuaikan agar:
///  - memakai model OcrResult/OcrLine/OcrBBox milik kontrak 5.2 (satu model
///    saja di seluruh app, tidak ada duplikat),
///  - timeout dibaca dari shared config (ocr_timeout_ms), bukan hardcode,
///  - confidence dibiarkan null (ML Kit tidak mengisinya) -> UI tidak
///    menandai baris tersebut.
class MlKitOcrEngine implements OcrEngine {
  final Duration timeout;

  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  MlKitOcrEngine({required this.timeout});

  @override
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(input).timeout(timeout);

      final lines = <OcrLine>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final r = line.boundingBox;
          lines.add(
            OcrLine(
              text: line.text,
              bbox: OcrBBox(
                x: r.left.round(),
                y: r.top.round(),
                width: r.width.round(),
                height: r.height.round(),
              ),
            ),
          );
        }
      }

      return OcrResult(
        imageId: imageId,
        engine: 'mlkit',
        fullText: recognized.text,
        lines: lines,
        processingMs: stopwatch.elapsedMilliseconds,
        status: 'ok',
      );
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

  @override
  Future<void> close() => _recognizer.close();
}
