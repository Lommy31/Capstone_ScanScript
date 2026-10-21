
class OcrLine {
  final String text;
  final Map<String, int> bbox;
  final double? confidence;

  const OcrLine({
    required this.text,
    required this.bbox,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'bbox': bbox,
        'confidence': confidence,
      };
}

class OcrResult {
  final String imageId;
  final String engine;
  final String fullText;
  final List<OcrLine> lines;
  final int processingMs;
  final String status;

  const OcrResult({
    required this.imageId,
    required this.engine,
    required this.fullText,
    required this.lines,
    required this.processingMs,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'image_id': imageId,
        'engine': engine,
        'full_text': fullText,
        'lines': lines.map((line) => line.toJson()).toList(),
        'processing_ms': processingMs,
        'status': status,
      };
}
