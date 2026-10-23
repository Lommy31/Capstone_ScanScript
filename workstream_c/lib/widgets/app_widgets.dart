import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Nav pill mengikuti mockup: Home | kamera (menonjol) | History + badge.
class AppNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onCamera;
  final int historyCount;

  const AppNavBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onCamera,
    this.historyCount = 0,
  });

  static const _blue = Color(0xFF4389E5);
  static const _inactive = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: SizedBox(
              height: 80,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14171717),
                          blurRadius: 24,
                          spreadRadius: -4,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: Icons.document_scanner_outlined,
                            activeIcon: Icons.document_scanner,
                            label: 'Home',
                            selected: index == 0,
                            onTap: () => onChanged(0),
                          ),
                        ),
                        const SizedBox(width: 64),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.history_edu_outlined,
                            activeIcon: Icons.history_edu,
                            label: 'History',
                            badge: historyCount,
                            selected: index == 1,
                            onTap: () => onChanged(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Tooltip(
                        message: 'Ambil foto',
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: Ink(
                            decoration: const BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x664389E5),
                                  blurRadius: 20,
                                  spreadRadius: -2,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onCamera,
                              child: const SizedBox(
                                width: 56,
                                height: 56,
                                child: Icon(
                                  Icons.photo_camera,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppNavBar._blue : AppNavBar._inactive;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, size: 24, color: color),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppNavBar._blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol ikon kotak 36px (biru / abu / olive / merah sesuai fungsi).
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Tag kecil warna tertiary (krem + teks olive).
class StatusTag extends StatelessWidget {
  final String label;
  final IconData? icon;

  const StatusTag({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.tertiary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar tipis (biru kalau aman, olive kalau di bawah threshold).
class ConfidenceBar extends StatelessWidget {
  final double value;
  final double threshold;

  const ConfidenceBar({
    super.key,
    required this.value,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        color: value < threshold ? AppColors.tertiary : AppColors.primary,
      ),
    );
  }
}
