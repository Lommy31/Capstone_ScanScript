import 'dart:ui' show TextRange;

import 'package:flutter_test/flutter_test.dart';
import 'package:workstream_c/logic/flag_ranges.dart';
import 'package:workstream_c/models/ocr_result.dart';

OcrLine line(String text, double? conf) => OcrLine(
  text: text,
  confidence: conf,
  bbox: const OcrBBox(x: 0, y: 0, width: 10, height: 10),
);

void main() {
  group('computeFlagRanges', () {
    test('menandai hanya baris di bawah threshold', () {
      final lines = [line('aaa', 0.9), line('bbb', 0.4), line('ccc', 0.8)];
      final ranges = computeFlagRanges('aaa\nbbb\nccc', lines, 0.65);
      expect(ranges, [const TextRange(start: 4, end: 7)]);
    });

    test('confidence tepat di threshold TIDAK ditandai', () {
      final ranges = computeFlagRanges('aaa', [line('aaa', 0.65)], 0.65);
      expect(ranges, isEmpty);
    });

    test('threshold berbeda menghasilkan flag berbeda (dari config)', () {
      final lines = [line('aaa', 0.7)];
      expect(computeFlagRanges('aaa', lines, 0.65), isEmpty);
      expect(computeFlagRanges('aaa', lines, 0.8), hasLength(1));
    });

    test('baris yang tidak ada di fullText dilewati tanpa crash', () {
      final ranges = computeFlagRanges('abc', [line('zzz', 0.1)], 0.65);
      expect(ranges, isEmpty);
    });

    test('baris duplikat dipetakan berurutan', () {
      final lines = [line('hi', 0.9), line('hi', 0.2)];
      final ranges = computeFlagRanges('hi\nhi', lines, 0.65);
      expect(ranges, [const TextRange(start: 3, end: 5)]);
    });

    test('baris tanpa confidence (null) TIDAK ditandai', () {
      final lines = [line('aaa', null), line('bbb', 0.4)];
      final ranges = computeFlagRanges('aaa\nbbb', lines, 0.65);
      expect(ranges, [const TextRange(start: 4, end: 7)]);
    });

    test('semua confidence null -> tidak ada flag', () {
      final lines = [line('aaa', null), line('bbb', null)];
      expect(computeFlagRanges('aaa\nbbb', lines, 0.65), isEmpty);
    });
  });

  group('adjustRanges', () {
    const flag = TextRange(start: 10, end: 15);

    test('edit sebelum flag menggeser flag', () {
      final r = adjustRanges('0123456789ABCDE', 'XX0123456789ABCDE', [flag]);
      expect(r, [const TextRange(start: 12, end: 17)]);
    });

    test('edit setelah flag tidak mengubah flag', () {
      final r = adjustRanges('0123456789ABCDE', '0123456789ABCDEXX', [flag]);
      expect(r, [flag]);
    });

    test('edit di dalam flag menghapus flag', () {
      final r = adjustRanges('0123456789ABCDE', '0123456789AXCDE', [flag]);
      expect(r, isEmpty);
    });

    test('hapus teks sebelum flag menggeser mundur', () {
      final r = adjustRanges('0123456789ABCDE', '23456789ABCDE', [flag]);
      expect(r, [const TextRange(start: 8, end: 13)]);
    });

    test('teks sama mengembalikan range yang sama', () {
      expect(adjustRanges('abc', 'abc', [flag]), [flag]);
    });
  });
}
