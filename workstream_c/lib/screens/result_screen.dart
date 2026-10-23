import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ocr_result.dart';
import '../models/scan_record.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/flagged_text_controller.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final String recordId;
  final DateTime createdAt;
  final String engine;

  /// null = engine tidak menyediakan confidence.
  final double? avgConfidence;
  final String status;
  final String initialText;

  /// Hanya ada untuk hasil OCR baru. Untuk item history, tanda low-confidence
  /// tidak disimpan, jadi teks dibuka tanpa underline.
  final OcrResult? result;

  const ResultScreen._({
    required this.imagePath,
    required this.recordId,
    required this.createdAt,
    required this.engine,
    required this.avgConfidence,
    required this.status,
    required this.initialText,
    required this.result,
  });

  factory ResultScreen.fromOcr({
    required String imagePath,
    required OcrResult result,
  }) => ResultScreen._(
    imagePath: imagePath,
    recordId: result.imageId,
    createdAt: DateTime.now(),
    engine: result.engine,
    avgConfidence: result.avgConfidence,
    status: result.status,
    initialText: result.fullText,
    result: result,
  );

  factory ResultScreen.fromRecord(ScanRecord record) => ResultScreen._(
    imagePath: record.imagePath,
    recordId: record.id,
    createdAt: record.createdAt,
    engine: record.engine,
    avgConfidence: record.avgConfidence,
    status: 'ok',
    initialText: record.text,
    result: null,
  );

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final FlaggedTextController _controller;

  bool get _failed => widget.status != 'ok';

  @override
  void initState() {
    super.initState();

    // Threshold SELALU dari shared config (tidak di-hardcode di UI).
    final threshold = Services.config.lowConfidenceThreshold;

    _controller = widget.result != null
        ? FlaggedTextController.fromResult(widget.result!, threshold)
        : FlaggedTextController(text: widget.initialText);

    // Simpan ke history begitu hasil muncul (kecuali OCR gagal total tanpa teks).
    if (!_failed) _persist();
  }

  Future<void> _persist() async {
    try {
      await Services.repo.save(
        ScanRecord(
          id: widget.recordId,
          imagePath: widget.imagePath,
          createdAt: widget.createdAt,
          text: _controller.text,
          avgConfidence: widget.avgConfidence,
          engine: widget.engine,
        ),
      );
    } catch (_) {
      // Gagal simpan history tidak boleh mengganggu user.
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copy() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return _toast('Tidak ada teks untuk disalin.');
    await Services.export.copyToClipboard(text);
    await _persist();
    _toast('Teks disalin ke clipboard.');
  }

  Future<void> _saveTxt() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return _toast('Tidak ada teks untuk disimpan.');
    try {
      await _persist();
      await Services.export.saveAndShareTxt(text, at: DateTime.now());
    } catch (e) {
      _toast('Gagal menyimpan .txt: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final threshold = Services.config.lowConfidenceThreshold;
    final avg = widget.avgConfidence;

    // Info confidence hanya ditampilkan kalau engine menyediakannya.
    final String title = _failed
        ? 'OCR gagal'
        : (avg != null
              ? 'Rata-rata confidence ${(avg * 100).round()}%'
              : 'Hasil pemindaian');
    final bool showFlagHint = !_failed && avg != null;

    return PopScope(
      // Simpan edit terakhir saat user keluar dari layar.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_failed) _persist();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Hasil')),
        body: SafeArea(
          child: Column(
            children: [
              if (_failed) _FallbackBanner(status: widget.status),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppDecor.card(),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.imagePath),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          cacheWidth: 160,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 56, height: 56),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (showFlagHint) ...[
                              const SizedBox(height: 8),
                              ConfidenceBar(value: avg, threshold: threshold),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiaryContainer,
                                      border: Border.all(
                                        color: AppColors.tertiary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Teks bertanda = confidence < ${(threshold * 100).round()}%, cek ulang.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.neutralMid,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecor.card(),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    style: textTheme.bodyLarge?.copyWith(height: 1.6),
                    decoration: InputDecoration(
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: _failed
                          ? 'Confidence rendah, silakan ketik ulang di sini.'
                          : 'Tidak ada teks terdeteksi.',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: AppButtons.secondary,
                        onPressed: _copy,
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Salin'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveTxt,
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Simpan .txt'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  final String status;

  const _FallbackBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final msg = status == 'timeout'
        ? 'OCR terlalu lama. Confidence rendah, silakan ketik ulang.'
        : 'OCR gagal membaca gambar. Silakan ketik ulang atau coba foto lagi.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D79F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(color: AppColors.tertiary)),
          ),
        ],
      ),
    );
  }
}
