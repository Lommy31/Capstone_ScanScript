import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  const ExportService();

  /// Salin ke clipboard.
  Future<void> copyToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }

  /// Tulis teks ke file .txt (UTF-8) dan kembalikan path-nya.
  Future<File> writeTxt(String text, {required DateTime at}) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) await exportDir.create(recursive: true);

    final stamp = _stamp(at);
    final file = File('${exportDir.path}/scanscript_$stamp.txt');
    await file.writeAsString(text, flush: true);
    return file;
  }

  /// Simpan .txt lalu buka share sheet Android, dari sana user bisa
  /// "Simpan ke perangkat", kirim ke Drive/WhatsApp, dll. Ini juga cara
  /// paling mudah untuk mengetes file terbuka di device lain.
  Future<File> saveAndShareTxt(String text, {required DateTime at}) async {
    final file = await writeTxt(text, at: at);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain')],
        subject: 'Hasil ScanScript',
      ),
    );
    return file;
  }

  /// Bagikan teks langsung lewat share sheet (WhatsApp, email, dll),
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Hasil ScanScript'),
    );
  }

  static String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }
}
