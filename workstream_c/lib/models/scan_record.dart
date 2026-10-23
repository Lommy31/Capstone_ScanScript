class ScanRecord {
  final String id;
  final String imagePath;
  final DateTime createdAt;
  final String text;

  final double? avgConfidence;
  final String engine;

  const ScanRecord({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.text,
    this.avgConfidence,
    required this.engine,
  });

  String get firstLine {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) return t;
    }
    return '(tidak ada teks)';
  }

  ScanRecord copyWith({String? text}) => ScanRecord(
    id: id,
    imagePath: imagePath,
    createdAt: createdAt,
    text: text ?? this.text,
    avgConfidence: avgConfidence,
    engine: engine,
  );

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
    id: json['id'] as String,
    imagePath: json['image_path'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    text: json['text'] as String? ?? '',
    avgConfidence: (json['avg_confidence'] as num?)?.toDouble(),
    engine: json['engine'] as String? ?? 'mlkit',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'image_path': imagePath,
    'created_at': createdAt.toIso8601String(),
    'text': text,
    'avg_confidence': avgConfidence,
    'engine': engine,
  };
}
