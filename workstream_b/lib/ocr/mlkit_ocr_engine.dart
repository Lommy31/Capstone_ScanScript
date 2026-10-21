import 'dart:async';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_engine.dart';
import 'ocr_result.dart';

class MlKitOcrEngine implements OcrEngine {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText =
          await _recognizer.processImage(inputImage).timeout(
        const Duration(seconds: 4),
      );

      final lines = <OcrLine>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final rect = line.boundingBox;

          lines.add(
            OcrLine(
              text: line.text,
              bbox: {
                'x': rect.left.round(),
                'y': rect.top.round(),
                'width': rect.width.round(),
                'height': rect.height.round(),
              },
            ),
          );
        }
      }

      stopwatch.stop();

      return OcrResult(
        imageId: imageId,
        engine: 'mlkit',
        fullText: recognizedText.text,
        lines: lines,
        processingMs: stopwatch.elapsedMilliseconds,
        status: 'ok',
      );
    } on TimeoutException {
      stopwatch.stop();

      return OcrResult(
        imageId: imageId,
        engine: 'mlkit',
        fullText: '',
        lines: const [],
        processingMs: stopwatch.elapsedMilliseconds,
        status: 'timeout',
      );
    } catch (_) {
      stopwatch.stop();

      return OcrResult(
        imageId: imageId,
        engine: 'mlkit',
        fullText: '',
        lines: const [],
        processingMs: stopwatch.elapsedMilliseconds,
        status: 'error',
      );
    }
  }

  @override
  Future<void> close() async {
    await _recognizer.close();
  }
}
