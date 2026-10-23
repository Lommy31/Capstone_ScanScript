import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Shared config (kontrak 5.3). Satu-satunya sumber threshold:
/// Workstream B dan C HARUS baca dari file yang sama (assets/config.json).
class AppConfig {
  final double lowConfidenceThreshold;
  final int ocrTimeoutMs;
  final double maxSkewCorrectionDeg;

  const AppConfig({
    required this.lowConfidenceThreshold,
    required this.ocrTimeoutMs,
    required this.maxSkewCorrectionDeg,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        lowConfidenceThreshold:
            (json['low_confidence_threshold'] as num).toDouble(),
        ocrTimeoutMs: (json['ocr_timeout_ms'] as num).toInt(),
        maxSkewCorrectionDeg:
            (json['max_skew_correction_deg'] as num).toDouble(),
      );

  static Future<AppConfig> load() async {
    final raw = await rootBundle.loadString('assets/config.json');
    return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
