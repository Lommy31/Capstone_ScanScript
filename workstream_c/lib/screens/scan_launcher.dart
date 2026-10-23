import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'camera_screen.dart';
import 'preview_screen.dart';

/// Pintu masuk scan: kamera = layar kamera sendiri, galeri = picker sistem.
class ScanLauncher {
  static final ImagePicker _picker = ImagePicker();
  static bool _busy = false;

  static Future<void> pick(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CameraScreen()));
      return;
    }
    await pickWithSystemPicker(context, source);
  }

  /// Picker bawaan sistem (galeri, atau kamera sistem sebagai cadangan).
  static Future<void> pickWithSystemPicker(
    BuildContext context,
    ImageSource source,
  ) async {
    if (_busy) return;
    _busy = true;

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (image == null) return;

      await nav.push(
        MaterialPageRoute(builder: (_) => PreviewScreen(imagePath: image.path)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuka gambar: $e')),
      );
    } finally {
      _busy = false;
    }
  }
}
