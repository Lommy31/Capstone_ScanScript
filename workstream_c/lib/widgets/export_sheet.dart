import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna mengikuti mockup Export (bottom sheet).
class _E {
  static const title = Color(0xFF111827);
  static const sub = Color(0xFF6B7280);
  static const divider = Color(0xFFF3F4F6);
  static const closeBg = Color(0xFFF3F4F6);
  static const handle = Color(0xFFD1D5DB);
  static const iconBg = Color(0xFFEFF6FF);
  static const iconFg = Color(0xFF3B82F6);
}

/// Bottom sheet "Ekspor catatan": salin, simpan sebagai file, bagikan.
class ExportSheet extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const ExportSheet({
    super.key,
    required this.onCopy,
    required this.onSave,
    required this.onShare,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCopy,
    required VoidCallback onSave,
    required VoidCallback onShare,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Latar & bayangan digambar sendiri di build() supaya sesuai mockup.
      backgroundColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      builder: (_) =>
          ExportSheet(onCopy: onCopy, onSave: onSave, onShare: onShare),
    );
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(32));

    void run(VoidCallback cb) {
      Navigator.of(context).pop();
      cb();
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x14171717),
            blurRadius: 35,
            offset: Offset(0, -10),
          ),
        ],
      ),
      // Material putih (bukan Container) supaya efek ripple InkWell terlihat.
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: _E.handle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ekspor catatan',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.55,
                              height: 1.25,
                              color: _E.title,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih cara untuk menyimpan atau membagikan teks.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _E.sub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: _E.closeBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.close, size: 20, color: _E.sub),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Opsi
              _Option(
                icon: Icons.content_copy_outlined,
                title: 'Salin teks',
                subtitle: 'Salin hasil koreksi ke clipboard.',
                onTap: () => run(onCopy),
              ),
              _Option(
                icon: Icons.download_outlined,
                title: 'Simpan sebagai file',
                subtitle: 'Simpan sebagai file TXT.',
                onTap: () => run(onSave),
              ),
              _Option(
                icon: Icons.share_outlined,
                title: 'Bagikan catatan',
                subtitle: 'Kirim melalui aplikasi lain.',
                divider: false,
                onTap: () => run(onShare),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool divider;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: _E.divider))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _E.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: _E.iconFg),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.375,
                      color: _E.title,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 13, color: _E.sub),
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
