import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ocr_result.dart';
import 'ocr_gateway.dart';

import 'dart:typed_data';

/// Integrasi Workstream A -> B.
/// Kirim foto ke server preprocessing (Python), simpan hasilnya ke file
/// sementara, lalu jalankan OCR [inner] pada gambar yang sudah dibersihkan.
///
/// Kalau server mati / tidak terjangkau / URL kosong, otomatis fallback ke
/// foto asli supaya aplikasi tetap jalan.
class PreprocessingOcrGateway implements OcrGateway {
  final OcrGateway inner;
  final String
  serverUrl; // contoh: http://192.168.1.10:8002 (kosong = nonaktif)
  final String method;
  final Duration timeout;

  const PreprocessingOcrGateway({
    required this.inner,
    required this.serverUrl,
    this.method = 'contrast_binarization',
    this.timeout = const Duration(seconds: 3),
  });

  @override
  Future<OcrResult> recognize({
    required String imagePath,
    required String imageId,
  }) async {
    final cleanedPath = await _preprocess(imagePath, imageId);
    debugPrint(
      cleanedPath == null
          ? '[Preprocess] dilewati / gagal, OCR pakai foto asli'
          : '[Preprocess] OK ($method), OCR pakai $cleanedPath',
    );

    return inner.recognize(
      imagePath: cleanedPath ?? imagePath,
      imageId: imageId,
    );
  }

  Future<String?> _preprocess(String imagePath, String imageId) async {
    if (serverUrl.isEmpty) return null;

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final uri = Uri.parse('$serverUrl/preprocess')
          .replace(queryParameters: {'method': method});
      final bytes = await File(imagePath).readAsBytes();

      final req = await client.postUrl(uri).timeout(timeout);
      req.headers.contentType = ContentType('image', 'jpeg');
      req.contentLength = bytes.length;
      req.add(bytes);

      final res = await req.close().timeout(timeout);
      if (res.statusCode != 200) {
        await res.drain<void>();
        return null;
      }

      final builder = await res
          .fold<BytesBuilder>(BytesBuilder(), (b, d) {
            b.add(d);
            return b;
          })
          .timeout(timeout);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pre_$imageId.png');
      await file.writeAsBytes(builder.takeBytes());
      return file.path;
    } catch (e) {
      debugPrint('[Preprocess] error: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
