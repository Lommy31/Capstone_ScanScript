import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scan_record.dart';
import '../services/services.dart';
import 'result_screen.dart';

/// Palet sesuai desain baru
class _C {
  static const bg = Color(0xFFF1F5FC);
  static const card = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const chip = Color(0xFFEFF3F8);
  static const primary = Color(0xFF4389E5);
  static const text = Color(0xFF171717);
  static const muted = Color(0xFF64748B);
  static const dot = Color(0xFFCBD5E1);
  static const footer = Color(0xFFFAFAFA);
  static const footerBorder = Color(0xFFF1F5F9);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const toast = Color(0xFF2F2E44);
}

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onChanged;

  const HistoryScreen({super.key, this.onChanged});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanRecord>> _future;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _future = Services.repo.list();
  }

  void _reload() {
    setState(() => _future = Services.repo.list());
    widget.onChanged?.call();
  }

  Future<void> _delete(ScanRecord r) async {
    await Services.repo.delete(r.id);
    _reload();
  }

  Future<void> _open(ScanRecord r) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ResultScreen.fromRecord(r)));
    if (mounted) _reload(); // teks mungkin sudah diedit
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _C.toast,
          elevation: 6,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 110),
          shape: const StadiumBorder(),
          duration: const Duration(milliseconds: 2400),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 18,
                color: Color(0xFFE7C359),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  msg,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF3EEFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _copy(ScanRecord r) async {
    await Services.export.copyToClipboard(r.text);
    _toast('Teks berhasil disalin ke clipboard');
  }

  Future<void> _share(ScanRecord r) async {
    try {
      await Services.export.saveAndShareTxt(r.text, at: DateTime.now());
    } catch (e) {
      _toast('Gagal membagikan: $e');
    }
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String formatDate(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)} ${_months[t.month - 1]} ${t.year}, ${two(t.hour)}:${two(t.minute)}';
  }

  Future<bool> _confirmDelete(ScanRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: _C.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: _C.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hapus Catatan Ini?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tindakan ini tidak dapat dibatalkan. Catatan akan dihapus permanen dari perangkat.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: _C.muted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _C.chip,
                            foregroundColor: _C.text,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _C.error,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  void _showMore(ScanRecord r) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.dot,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OPSI CATATAN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: _C.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.firstLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _C.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CircleIconButton(
                    icon: Icons.close,
                    size: 36,
                    iconSize: 20,
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _OptionTile(
                icon: Icons.edit_note,
                color: _C.primary,
                title: 'Edit Naskah & Transkripsi',
                subtitle: 'Koreksi kata dengan editor teks',
                onTap: () {
                  Navigator.pop(ctx);
                  _open(r);
                },
              ),
              _OptionTile(
                icon: Icons.file_download_outlined,
                color: _C.muted,
                title: 'Ekspor sebagai TXT',
                subtitle: 'Simpan atau bagikan berkas teks',
                onTap: () {
                  Navigator.pop(ctx);
                  _share(r);
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                color: _C.error,
                background: _C.errorContainer,
                titleColor: _C.error,
                subtitleColor: _C.onErrorContainer,
                title: 'Hapus Catatan',
                subtitle: 'Hapus secara permanen dari perangkat',
                onTap: () async {
                  Navigator.pop(ctx);
                  if (await _confirmDelete(r)) _delete(r);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(ScanRecord r) {
    final snippet = r.text.trim();

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(r),
      onDismissed: (_) => _delete(r),
      background: Container(
        decoration: BoxDecoration(
          color: _C.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _open(r),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _thumbnail(r),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              formatDate(r.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: _C.muted,
                              ),
                            ),
                            if (snippet.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '“$snippet”',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: _C.text,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: _C.footer,
                    border: Border(top: BorderSide(color: _C.footerBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _CircleIconButton(
                        icon: Icons.content_copy,
                        tooltip: 'Salin teks',
                        onPressed: () => _copy(r),
                      ),
                      const SizedBox(width: 4),
                      _CircleIconButton(
                        icon: Icons.share,
                        tooltip: 'Bagikan',
                        onPressed: () => _share(r),
                      ),
                      const SizedBox(width: 4),
                      _CircleIconButton(
                        icon: Icons.more_vert,
                        tooltip: 'Opsi lainnya',
                        onPressed: () => _showMore(r),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(ScanRecord r) {
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        color: _C.chip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(r.imagePath),
            fit: BoxFit.cover,
            cacheWidth: 160,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.image_not_supported_outlined, color: _C.muted),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _C.chip,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _C.dot),
              ),
              child: Text(
                'TXT',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _C.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        shape: const Border(bottom: BorderSide(color: _C.border)),
        title: Text(
          'ScanScript',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: _C.text,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CircleIconButton(
              icon: Icons.person_outline,
              size: 40,
              iconSize: 20,
              color: _C.primary,
              tooltip: 'Profil Pengguna',
              onPressed: () {}, // TODO: arahkan ke halaman profil
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ScanRecord>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = [...(snap.data ?? const <ScanRecord>[])]
            ..sort(
              (a, b) => _newestFirst
                  ? b.createdAt.compareTo(a.createdAt)
                  : a.createdAt.compareTo(b.createdAt),
            );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Riwayat Scan',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        height: 32 / 26,
                        fontWeight: FontWeight.w700,
                        color: _C.text,
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.swap_vert,
                    size: 40,
                    iconSize: 20,
                    color: _C.primary,
                    tooltip: _newestFirst ? 'Terlama dulu' : 'Terbaru dulu',
                    onPressed: () =>
                        setState(() => _newestFirst = !_newestFirst),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: _C.chip,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.history_edu,
                          color: _C.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada hasil scan.',
                        style: GoogleFonts.inter(fontSize: 14, color: _C.muted),
                      ),
                    ],
                  ),
                )
              else
                for (final r in items) ...[_card(r), const SizedBox(height: 8)],
              // ruang agar tidak tertutup bottom nav
              const SizedBox(height: 72),
            ],
          );
        },
      ),
    );
  }
}

/// Tombol ikon bulat sesuai desain (default 36px, bg chip, ikon abu)
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color color;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 36,
    this.iconSize = 18,
    this.color = _C.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: _C.chip,
        shape: size >= 40
            ? const CircleBorder(side: BorderSide(color: _C.border))
            : const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final Color titleColor;
  final Color subtitleColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.background,
    this.titleColor = _C.text,
    this.subtitleColor = _C.muted,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: background ?? _C.chip,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: subtitleColor,
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
}
