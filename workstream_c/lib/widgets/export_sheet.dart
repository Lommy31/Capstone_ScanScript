import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom sheet "Ekspor Catatan".
class ExportSheet extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onSave;

  const ExportSheet({super.key, required this.onCopy, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCopy,
    required VoidCallback onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ExportSheet(onCopy: onCopy, onSave: onSave),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    void run(VoidCallback cb) {
      Navigator.of(context).pop();
      cb();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.output, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Ekspor Catatan', style: t.titleLarge),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Simpan atau bagikan teks digital yang telah dikoreksi.',
              style: t.bodySmall?.copyWith(color: AppColors.neutralMid),
            ),
            const SizedBox(height: 16),
            _Row(
              icon: Icons.content_copy,
              title: 'Salin ke Clipboard',
              action: 'Salin',
              actionIcon: Icons.check_box_outlined,
              onTap: () => run(onCopy),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.text_snippet_outlined,
              title: 'Simpan & Bagikan (.txt)',
              action: 'Bagikan',
              actionIcon: Icons.ios_share,
              onTap: () => run(onSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String action;
  final IconData actionIcon;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.title,
    required this.action,
    required this.actionIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: onTap,
            icon: Icon(actionIcon, size: 16),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}
