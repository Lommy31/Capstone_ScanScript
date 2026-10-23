import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'preview_screen.dart';
import 'scan_launcher.dart';

/// Warna mengikuti mockup S02 — Camera Capture.
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  String? _error;
  bool _grid = false;
  bool _auto = true;
  bool _capturing = false;
  bool _pulse = false;
  bool _toast = false;
  bool _pressed = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _anim.dispose();
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

  Future<void> _setAuto(bool auto) async {
    setState(() => _auto = auto);
    try {
      await _controller?.setFocusMode(auto ? FocusMode.auto : FocusMode.locked);
    } catch (_) {}
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
              final viewportH = math.max(
                240.0,
                math.min(box.maxWidth * 4 / 3, box.maxHeight - 200),
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
                        Text(
                          'Dokumen tertangkap • Memproses OCR...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
            DecoratedBox(
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
            if (_grid)
              const IgnorePointer(
                child: CustomPaint(
                  painter: _GridPainter(),
                  size: Size.infinite,
                ),
              ),
            _laser(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundBtn(
                        icon: Icons.close,
                        size: 40,
                        iconSize: 20,
                        bg: _C.inverse.withValues(alpha: 0.6),
                        fg: const Color(0xFFF3EEFF),
                        shadow: true,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      _RoundBtn(
                        icon: Icons.grid_on,
                        size: 40,
                        iconSize: 20,
                        bg: _C.inverse.withValues(alpha: 0.6),
                        fg: _grid
                            ? const Color(0xFFE4DFFF)
                            : Colors.white.withValues(alpha: 0.6),
                        shadow: true,
                        onTap: () => setState(() => _grid = !_grid),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AspectRatio(
                        aspectRatio: 1 / 1.38,
                        child: _frame(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _hintPill(),
                ),
              ],
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

  Widget _laser() {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.33),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, child) =>
                Opacity(opacity: 1 - 0.5 * _anim.value, child: child),
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, _C.blue, Colors.transparent],
                ),
                boxShadow: [BoxShadow(color: _C.blue, blurRadius: 12)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _frame() {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _C.blue.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const Positioned(
            top: -4,
            left: -4,
            child: _Corner(flipX: false, flipY: false),
          ),
          const Positioned(
            top: -4,
            right: -4,
            child: _Corner(flipX: true, flipY: false),
          ),
          const Positioned(
            bottom: -4,
            left: -4,
            child: _Corner(flipX: false, flipY: true),
          ),
          const Positioned(
            bottom: -4,
            right: -4,
            child: _Corner(flipX: true, flipY: true),
          ),
          Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_center_focus,
                size: 18,
                color: _C.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _C.inverse.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1 + _anim.value,
                      child: Opacity(
                        opacity: (1 - _anim.value) * 0.75,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: _C.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _C.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Sejajarkan naskah • Pencahayaan ideal',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Kontrol bawah ----------------

  Widget _controls() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _modeToggle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SideBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: _gallery,
                  ),
                  _shutter(),
                  _SideBtn(
                    icon: Icons.filter_none,
                    label: 'Batch',
                    onTap: () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Mode batch belum tersedia.'),
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeToggle() {
    Widget btn(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _C.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? Colors.white : _C.text,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn('Auto', _auto, () => _setAuto(true)),
          btn('Manual', !_auto, () => _setAuto(false)),
        ],
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
  final bool shadow;
  final VoidCallback onTap;

  const _RoundBtn({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
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

class _Corner extends StatelessWidget {
  final bool flipX;
  final bool flipY;

  const _Corner({required this.flipX, required this.flipY});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: _CornerPainter(flipX: flipX, flipY: flipY),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool flipX;
  final bool flipY;

  const _CornerPainter({required this.flipX, required this.flipY});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (flipX) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    if (flipY) {
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }

    final path = Path()
      ..moveTo(2.5, size.height)
      ..lineTo(2.5, 10)
      ..quadraticBezierTo(2.5, 2.5, 10, 2.5)
      ..lineTo(size.width, 2.5);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = _C.blue
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = _C.blue;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.flipX != flipX || old.flipY != flipY;
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE9E5FF).withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), p);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
