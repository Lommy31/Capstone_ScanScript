import 'package:flutter_test/flutter_test.dart';
import 'package:workstream_c/config/app_config.dart';
import 'package:workstream_c/models/ocr_result.dart';
import 'package:workstream_c/models/scan_record.dart';

void main() {
  group('OcrResult (kontrak 5.2)', () {
    final json = {
      'image_id': 'abc',
      'engine': 'mlkit',
      'full_text': 'hello\nworld',
      'lines': [
        {
          'text': 'hello',
          'confidence': 0.9,
          'bbox': {'x': 1, 'y': 2, 'width': 3, 'height': 4},
          'low_confidence': false,
        },
        {
          'text': 'world',
          'confidence': 0.3,
          'bbox': {'x': 5, 'y': 6, 'width': 7, 'height': 8},
          'low_confidence': true,
        },
      ],
      'avg_confidence': 0.6,
      'processing_ms': 120,
      'status': 'ok',
    };

    test('fromJson membaca semua field', () {
      final r = OcrResult.fromJson(json);
      expect(r.imageId, 'abc');
      expect(r.lines, hasLength(2));
      expect(r.lines[1].bbox.width, 7);
      expect(r.avgConfidence, 0.6);
      expect(r.isOk, isTrue);
    });

    test('toJson round-trip', () {
      expect(OcrResult.fromJson(json).toJson(), json);
    });

    test('field hilang tidak membuat crash', () {
      final r = OcrResult.fromJson({'image_id': 'x'});
      expect(r.fullText, '');
      expect(r.lines, isEmpty);
      expect(r.status, 'error');
    });

    test('failed() menghasilkan hasil kosong dengan status yang diminta', () {
      final r = OcrResult.failed(imageId: 'x', status: 'timeout');
      expect(r.isOk, isFalse);
      expect(r.fullText, isEmpty);
      expect(r.avgConfidence, isNull);
    });

    test('confidence dan avg_confidence boleh hilang (null)', () {
      final r = OcrResult.fromJson({
        'image_id': 'abc',
        'full_text': 'hi',
        'lines': [
          {
            'text': 'hi',
            'bbox': {'x': 0, 'y': 0, 'width': 1, 'height': 1},
          },
        ],
        'status': 'ok',
      });
      expect(r.avgConfidence, isNull);
      expect(r.lines.first.confidence, isNull);
      expect(r.isOk, isTrue);
    });

    test('toJson round-trip dengan confidence null', () {
      final r = OcrResult.fromJson({
        'image_id': 'abc',
        'full_text': 'hi',
        'lines': [
          {
            'text': 'hi',
            'confidence': null,
            'bbox': {'x': 0, 'y': 0, 'width': 1, 'height': 1},
          },
        ],
        'avg_confidence': null,
        'status': 'ok',
      });
      final back = OcrResult.fromJson(r.toJson());
      expect(back.avgConfidence, isNull);
      expect(back.lines.first.confidence, isNull);
    });

    test('isLowConfidence: null tidak dianggap rendah', () {
      const bbox = OcrBBox(x: 0, y: 0, width: 1, height: 1);
      expect(
        const OcrLine(text: 'a', bbox: bbox).isLowConfidence(0.65),
        isFalse,
      );
      expect(
        const OcrLine(
          text: 'a',
          confidence: 0.3,
          bbox: bbox,
        ).isLowConfidence(0.65),
        isTrue,
      );
    });
  });

  group('ScanRecord', () {
    ScanRecord make(String text) => ScanRecord(
      id: '1',
      imagePath: '/tmp/a.png',
      createdAt: DateTime.utc(2026, 10, 21, 8, 30),
      text: text,
      avgConfidence: 0.8,
      engine: 'mlkit',
    );

    test('firstLine melewati baris kosong', () {
      expect(make('\n  \nHalo dunia\nbaris 2').firstLine, 'Halo dunia');
    });

    test('firstLine untuk teks kosong', () {
      expect(make('').firstLine, '(tidak ada teks)');
    });

    test('json round-trip', () {
      final r = make('abc');
      final back = ScanRecord.fromJson(r.toJson());
      expect(back.id, r.id);
      expect(back.createdAt, r.createdAt);
      expect(back.text, 'abc');
    });

    test('json round-trip dengan avgConfidence null', () {
      final r = ScanRecord(
        id: '2',
        imagePath: '/tmp/b.png',
        createdAt: DateTime.utc(2026, 10, 21, 9, 0),
        text: 'tanpa confidence',
        engine: 'mlkit',
      );
      final back = ScanRecord.fromJson(r.toJson());
      expect(back.avgConfidence, isNull);
      expect(back.text, 'tanpa confidence');
    });

    test('copyWith hanya mengubah teks', () {
      final r = make('lama').copyWith(text: 'baru');
      expect(r.text, 'baru');
      expect(r.id, '1');
    });
  });

  group('AppConfig (kontrak 5.3)', () {
    test('fromJson', () {
      final c = AppConfig.fromJson({
        'low_confidence_threshold': 0.65,
        'ocr_timeout_ms': 4000,
        'max_skew_correction_deg': 15,
      });
      expect(c.lowConfidenceThreshold, 0.65);
      expect(c.ocrTimeoutMs, 4000);
      expect(c.maxSkewCorrectionDeg, 15.0);
    });
  });
}
