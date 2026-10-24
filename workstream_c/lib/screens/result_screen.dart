import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  Timer? _debounce;

  /// Teks terakhir yang sudah tersimpan di history.
  String? _lastSaved;

  bool get _failed => widget.status != 'ok';

  @override
  void initState() {
    super.initState();

    // Threshold SELALU dari shared config (tidak di-hardcode di UI).
    final threshold = Services.config.lowConfidenceThreshold;

    _controller = widget.result != null
        ? FlaggedTextController.fromResult(widget.result!, threshold)
        : FlaggedTextController(text: widget.initialText);

    // Autosave: simpan setiap kali teks berubah (debounce).
    _controller.addListener(_onTextChanged);

    // Simpan ke history begitu hasil muncul (kecuali OCR gagal total tanpa teks).
    if (!_failed) _persist();
  }

  void _onTextChanged() {
    if (_failed) return;
    if (_controller.text == _lastSaved) return; // cuma kursor yang bergerak
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _persist);
  }

  Future<void> _persist() async {
    final text = _controller.text;
    if (text == _lastSaved) return;
    try {
      await Services.repo.save(
        ScanRecord(
          id: widget.recordId,
          imagePath: widget.imagePath,
          createdAt: widget.createdAt,
          text: text,
          avgConfidence: widget.avgConfidence,
          engine: widget.engine,
        ),
      );
      _lastSaved = text;
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

  /// Buka foto layar penuh (bisa di-zoom dan digeser).
  void _openImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ImageViewerScreen(imagePath: widget.imagePath),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
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
      // Tahan back sampai edit terakhir benar-benar tersimpan, supaya
      // HistoryScreen._reload() membaca teks yang sudah terbaru.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _debounce?.cancel();
        if (!_failed) await _persist();
        if (mounted) Navigator.of(context).pop();
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
                  decoration: AppDecor.card(),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openImage,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(widget.imagePath),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    cacheWidth: 160,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox(width: 56, height: 56),
                                  ),
                                ),
                                Positioned(
                                  right: 3,
                                  bottom: 3,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.zoom_out_map,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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
                                    ConfidenceBar(
                                      value: avg,
                                      threshold: threshold,
                                    ),
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
                                            style: textTheme.bodySmall
                                                ?.copyWith(
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
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Toolbar bawah (desain baru): bar putih dengan garis atas,
  /// tombol "Salin" (abu-biru) dan "Ekspor .txt" (biru solid).
  Widget _buildActionBar() {
    const border = Color(0xFFE2E8F0);
    const chip = Color(0xFFEFF3F8);
    const text = Color(0xFF171717);
    const blue = Color(0xFF4389E5);

    final labelStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: chip,
                  foregroundColor: text,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: border),
                  ),
                  textStyle: labelStyle,
                ),
                onPressed: _copy,
                icon: const Icon(Icons.content_copy, size: 20),
                label: const Text('Salin'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: blue.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: labelStyle,
                ),
                onPressed: _saveTxt,
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Ekspor .txt'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layar penuh untuk melihat foto: pinch untuk zoom, geser untuk pindah,
/// ketuk dua kali untuk reset.
class _ImageViewerScreen extends StatefulWidget {
  final String imagePath;

  const _ImageViewerScreen({required this.imagePath});

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  final _tc = TransformationController();

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Foto pemindaian',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: GestureDetector(
        onDoubleTap: () => _tc.value = Matrix4.identity(),
        child: InteractiveViewer(
          transformationController: _tc,
          minScale: 1,
          maxScale: 6,
          child: Center(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Text(
                  'Gambar tidak bisa ditampilkan.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
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
