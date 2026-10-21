
import 'ocr_result.dart';

abstract class OcrEngine {
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  });

  Future<void> close();
}
