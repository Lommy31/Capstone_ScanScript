class OcrBBox {
  final int x;
  final int y;
  final int width;
  final int height;

  const OcrBBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory OcrBBox.fromJson(Map<String, dynamic> json) => OcrBBox(
    x: (json['x'] as num).toInt(),
    y: (json['y'] as num).toInt(),
    width: (json['width'] as num).toInt(),
    height: (json['height'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}

class OcrLine {
  final String text;

  final double? confidence;
  final OcrBBox bbox;

  final bool lowConfidence;

  const OcrLine({
    required this.text,
    this.confidence,
    required this.bbox,
    this.lowConfidence = false,
  });

  bool isLowConfidence(double threshold) {
    final c = confidence;
    return c != null && c < threshold;
  }

  factory OcrLine.fromJson(Map<String, dynamic> json) => OcrLine(
    text: json['text'] as String? ?? '',
    confidence: (json['confidence'] as num?)?.toDouble(),
    bbox: OcrBBox.fromJson(json['bbox'] as Map<String, dynamic>),
    lowConfidence: json['low_confidence'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'confidence': confidence,
    'bbox': bbox.toJson(),
    'low_confidence': lowConfidence,
  };
}

/// status: "ok" | "timeout" | "error"
class OcrResult {
  final String imageId;
  final String engine;
  final String fullText;
  final List<OcrLine> lines;

  final double? avgConfidence;
  final int processingMs;
  final String status;

  const OcrResult({
    required this.imageId,
    required this.engine,
    required this.fullText,
    required this.lines,
    this.avgConfidence,
    required this.processingMs,
    required this.status,
  });

  bool get isOk => status == 'ok';

  factory OcrResult.failed({
    required String imageId,
    required String status,
    String engine = 'mlkit',
    int processingMs = 0,
  }) => OcrResult(
    imageId: imageId,
    engine: engine,
    fullText: '',
    lines: const [],
    avgConfidence: null,
    processingMs: processingMs,
    status: status,
  );

  factory OcrResult.fromJson(Map<String, dynamic> json) => OcrResult(
    imageId: json['image_id'] as String,
    engine: json['engine'] as String? ?? 'mlkit',
    fullText: json['full_text'] as String? ?? '',
    lines: (json['lines'] as List<dynamic>? ?? [])
        .map((e) => OcrLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    avgConfidence: (json['avg_confidence'] as num?)?.toDouble(),
    processingMs: (json['processing_ms'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'error',
  );

  Map<String, dynamic> toJson() => {
    'image_id': imageId,
    'engine': engine,
    'full_text': fullText,
    'lines': lines.map((l) => l.toJson()).toList(),
    'avg_confidence': avgConfidence,
    'processing_ms': processingMs,
    'status': status,
  };
}
