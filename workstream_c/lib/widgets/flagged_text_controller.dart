import 'package:flutter/material.dart';

import '../logic/flag_ranges.dart';
import '../models/ocr_result.dart';
import '../theme/app_theme.dart';

/// TextEditingController yang menggarisbawahi (wavy oranye) teks ber-confidence
/// rendah. Saat user mengedit bagian yang ditandai, tandanya hilang otomatis.
class FlaggedTextController extends TextEditingController {
  List<TextRange> _flags;
  String _prevText;

  FlaggedTextController({
    required String text,
    List<TextRange> flags = const [],
  }) : _flags = List.of(flags),
       _prevText = text,
       super(text: text) {
    addListener(_onChanged);
  }

  /// Bangun dari hasil OCR memakai threshold dari shared config.
  factory FlaggedTextController.fromResult(OcrResult result, double threshold) {
    return FlaggedTextController(
      text: result.fullText,
      flags: computeFlagRanges(result.fullText, result.lines, threshold),
    );
  }

  int get flaggedCount => _flags.length;

  void _onChanged() {
    if (text == _prevText) return; // hanya perubahan selection/cursor
    _flags = adjustRanges(_prevText, text, _flags);
    _prevText = text;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_flags.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final flagStyle = TextStyle(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: AppColors.tertiary,
      backgroundColor: AppColors.tertiaryContainer,
    );

    final sorted = List.of(_flags)..sort((a, b) => a.start.compareTo(b.start));
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final r in sorted) {
      final start = r.start.clamp(0, text.length);
      final end = r.end.clamp(0, text.length);
      if (end <= cursor) continue;
      final from = start < cursor ? cursor : start;

      if (from > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, from)));
      }
      spans.add(TextSpan(text: text.substring(from, end), style: flagStyle));
      cursor = end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(style: style, children: spans);
  }

  @override
  void dispose() {
    removeListener(_onChanged);
    super.dispose();
  }
}
