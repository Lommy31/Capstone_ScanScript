import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'scan_launcher.dart';

/// Warna & ukuran mengikuti mockup S01 — Home.
class _M {
  static const bg = Color(0xFFF1F5FC);
  static const blue = Color(0xFF4389E5);
  static const blueDark = Color(0xFF2B70CD);
  static const text = Color(0xFF171717);
  static const border = Color(0xFFE2E8F0);
  static const chip = Color(0xFFEFF3F8);
}

class HomeScreen extends StatelessWidget {
  final VoidCallback? onReturn;

  const HomeScreen({super.key, this.onReturn});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    await ScanLauncher.pick(context, source);
    onReturn?.call();
  }

  static const _shadowSm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _M.border),
    boxShadow: _shadowSm,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _M.bg,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _M.border)),
        titleSpacing: 16,
        title: Text(
          'ScanScript',
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.475,
            color: _M.text,
          ),
        ),
        actions: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _M.chip,
              shape: BoxShape.circle,
              border: Border.all(color: _M.border),
            ),
            child: const Icon(Icons.person_outline, size: 20, color: _M.blue),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Greeting
          Text(
            'Hey, ready to get started?',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
              color: _M.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan your handwritten notes and turn them into editable text.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.625,
              color: const Color(0xFF555E6D),
            ),
          ),
          const SizedBox(height: 20),

          // Pindai Dokumen
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x594389E5),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_M.blue, _M.blueDark]),
                  ),
                  child: InkWell(
                    onTap: () => _pick(context, ImageSource.camera),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -24,
                          bottom: -24,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 12,
                              sigmaY: 12,
                            ),
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.photo_camera,
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Pindai Dokumen',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
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
          const SizedBox(height: 12),

          // Impor dari Galeri
          Container(
            decoration: _card(),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _pick(context, ImageSource.gallery),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _M.chip,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 26,
                          color: _M.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Impor dari Galeri',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _M.text,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 22,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card(),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    size: 20,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips Pencahayaan Optimal',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _M.text,
                        ),
                      ),
                      Text(
                        'Posisikan kamera sejajar dengan kertas dan hindari bayangan tangan.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.625,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
