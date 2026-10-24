import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'preview_screen.dart';
import 'scan_launcher.dart';

/// Warna mengikuti mockup S02 — Camera Capture (tampilan clean).
class _C {
  static const bg = Color(0xFFF1F5FC);
  static const surface = Color(0xFFFCF8FF);
  static const blue = Color(0xFF4389E5);
  static const blue2 = Color(0xFF2B6CBF);
  static const text = Color(0xFF171717);
  static const border = Color(0xFFE2E8F0);
  static const chip = Color(0xFFEFF3F8);
  static const inverse = Color(0xFF2F2E44);
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;
  bool _pulse = false;
  bool _toast = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      setState(() => _controller = null);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        throw CameraException('none', 'Tidak ada kamera');
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await c.initialize();
      try {
        await c.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code.contains('AccessDenied')
            ? 'Izin kamera ditolak.'
            : 'Kamera tidak bisa dibuka.',
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Kamera tidak bisa dibuka.');
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing) return;

    setState(() {
      _capturing = true;
      _pulse = true;
      _toast = true;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _pulse = false);
    });

    try {
      final file = await c.takePicture();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PreviewScreen(imagePath: file.path)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
          _toast = false;
        });
      }
    }
  }

  Future<void> _gallery() async {
    await ScanLauncher.pickWithSystemPicker(context, ImageSource.gallery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _C.border)),
        titleSpacing: 16,
        title: Row(
          children: [
            _RoundBtn(
              icon: Icons.arrow_back,
              size: 40,
              iconSize: 22,
              bg: _C.chip,
              fg: _C.text,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            Text(
              'Camera',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _C.text,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _C.chip,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
            ),
            child: const Icon(Icons.person_outline, size: 20, color: _C.blue),
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              // Sisakan ruang untuk area kontrol bawah (shutter + padding
              // + safe area gesture bar).
              final viewportH = math.max(
                240.0,
                math.min(box.maxWidth * 4 / 3, box.maxHeight - 164),
              );
              return Column(
                children: [
                  SizedBox(height: viewportH, child: _viewport()),
                  Expanded(child: _controls()),
                ],
              );
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _toast ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _C.text,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: _C.blue,
                        ),
                        const SizedBox(width: 8),
                        // Flexible: teks boleh mengecil/terpotong, tidak overflow
                        Flexible(
                          child: Text(
                            'Dokumen tertangkap • Memproses OCR...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Viewport ----------------

  Widget _viewport() {
    const radius = BorderRadius.vertical(bottom: Radius.circular(32));
    return Container(
      decoration: const BoxDecoration(
        color: _C.inverse,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 50,
            spreadRadius: -12,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _preview(),
            // Gradient tipis atas-bawah. IgnorePointer supaya tidak menutupi
            // tombol di dalam _preview() (mis. "Pakai kamera sistem").
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _C.inverse.withValues(alpha: 0.9),
                      Colors.transparent,
                      _C.inverse.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final c = _controller;
    if (c != null && c.value.isInitialized && c.value.previewSize != null) {
      final s = c.value.previewSize!;
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: s.height,
          height: s.width,
          child: CameraPreview(c),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await ScanLauncher.pickWithSystemPicker(
                    context,
                    ImageSource.camera,
                  );
                },
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Pakai kamera sistem'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: Colors.white70),
    );
  }

  // ---------------- Kontrol bawah ----------------

  Widget _controls() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 48,
                  child: _SideBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: _gallery,
                  ),
                ),
                _shutter(),
                // Spacer selebar kolom Galeri supaya shutter tetap di tengah.
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shutter() {
    return Semantics(
      button: true,
      label: 'Ambil Foto Naskah',
      child: GestureDetector(
        onTap: _capture,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: _pulse ? 1.25 : 0.9,
                duration: const Duration(milliseconds: 300),
                child: AnimatedOpacity(
                  opacity: _pulse ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _C.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              AnimatedScale(
                scale: _pressed ? 0.9 : 1,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.blue, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _C.blue.withValues(alpha: 0.35),
                        blurRadius: 25,
                        spreadRadius: -5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_C.blue, _C.blue2],
                        ),
                      ),
                      child: const Icon(
                        Icons.document_scanner_outlined,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _RoundBtn({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _C.chip,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Icon(icon, size: 20, color: _C.text),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.text,
          ),
        ),
      ],
    );
  }
}
