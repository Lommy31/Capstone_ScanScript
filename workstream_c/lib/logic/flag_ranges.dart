import 'dart:ui' show TextRange;

import '../models/ocr_result.dart';

/// Petakan baris ber-confidence rendah ke range karakter di [fullText].
///
/// Kontrak 5.2 hanya memberi confidence per baris, jadi seluruh baris
/// ditandai. Kalau B nanti menambah confidence per kata, cukup ubah fungsi ini.
List<TextRange> computeFlagRanges(
  String fullText,
  List<OcrLine> lines,
  double threshold,
) {
  final ranges = <TextRange>[];
  var cursor = 0;

  for (final line in lines) {
    final text = line.text;
    if (text.isEmpty) continue;

    final start = fullText.indexOf(text, cursor);
    if (start < 0) continue; // teks baris tidak ketemu -> lewati, jangan crash
    final end = start + text.length;
    cursor = end;

    if (line.isLowConfidence(threshold)) {
      ranges.add(TextRange(start: start, end: end));
    }
  }
  return ranges;
}

/// Sesuaikan [ranges] setelah teks berubah dari [oldText] ke [newText].
/// - Range sebelum area edit: tetap.
/// - Range setelah area edit: digeser.
/// - Range yang kena edit: dihapus (dianggap sudah dikoreksi user).
List<TextRange> adjustRanges(
  String oldText,
  String newText,
  List<TextRange> ranges,
) {
  if (oldText == newText) return ranges;

  var prefix = 0;
  final minLen =
      oldText.length < newText.length ? oldText.length : newText.length;
  while (prefix < minLen && oldText[prefix] == newText[prefix]) {
    prefix++;
  }

  var suffix = 0;
  while (suffix < minLen - prefix &&
      oldText[oldText.length - 1 - suffix] ==
          newText[newText.length - 1 - suffix]) {
    suffix++;
  }

  final removedEnd = oldText.length - suffix; // akhir area yang diganti (lama)
  final delta = newText.length - oldText.length;

  final result = <TextRange>[];
  for (final r in ranges) {
    if (r.end <= prefix) {
      result.add(r);
    } else if (r.start >= removedEnd) {
      result.add(TextRange(start: r.start + delta, end: r.end + delta));
    }
    // selain itu: tumpang tindih dengan edit -> drop
  }
  return result;
}
