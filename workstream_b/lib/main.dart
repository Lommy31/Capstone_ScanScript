import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr/mlkit_ocr_engine.dart';
import 'ocr/ocr_result.dart';

void main() {
  runApp(const ScanScriptApp());
}

class ScanScriptApp extends StatelessWidget {
  const ScanScriptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanScript',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const ScanScriptHomePage(),
    );
  }
}

class ScanScriptHomePage extends StatefulWidget {
  const ScanScriptHomePage({super.key});

  @override
  State<ScanScriptHomePage> createState() => _ScanScriptHomePageState();
}

class _ScanScriptHomePageState extends State<ScanScriptHomePage> {
  final ImagePicker _picker = ImagePicker();
  final MlKitOcrEngine _ocrEngine = MlKitOcrEngine();

  File? _selectedImage;
  OcrResult? _result;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedImage = File(image.path);
        _result = null;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memilih gambar: $e';
      });
    }
  }

  Future<void> _fetchPreprocessedImage(int imageNumber) async {
    if (_isProcessing) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        'http://192.168.0.155:8000/preprocessed-image/$imageNumber',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      final directory = await Directory.systemTemp.createTemp('scanscript_');

      final imageFile = File('${directory.path}/preprocessed.png');

      await imageFile.writeAsBytes(response.bodyBytes);

      if (!mounted) return;

      setState(() {
        _selectedImage = imageFile;
        _result = null;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal mengambil gambar dari Workstream A: $e';
      });
    }
  }

  Future<void> _exportJson() async {
    if (_result == null) return;

    try {
      final jsonString = const JsonEncoder.withIndent('  ')
          .convert(_result!.toJson());

      final uri = Uri.parse('http://192.168.0.155:8001/upload-json');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonString,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON berhasil dikirim ke laptop!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengirim JSON: $e')));
    }
  }

  Future<void> _recognizeText() async {
    if (_selectedImage == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _ocrEngine.recognize(
        imagePath: _selectedImage!.path,
        imageId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        if (result.status != 'ok') {
          _errorMessage = 'OCR belum berhasil. Status: ${result.status}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat OCR: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ocrEngine.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.document_scanner_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('ScanScript', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Ubah gambar menjadi teks',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pindai dokumen dan ekstrak teks '
                'menggunakan teknologi OCR.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    if (_selectedImage == null) ...[
                      const Icon(
                        Icons.image_search_outlined,
                        size: 72,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mulai pemindaian',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih gambar dokumen dari galeri '
                        'untuk mengenali teks di dalamnya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, height: 1.5),
                      ),
                    ] else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gambar siap dipindai',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pilih gambar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final imageNumber = await showDialog<int>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return SimpleDialog(
                                      title: const Text('Pilih gambar'),
                                      children: List.generate(10, (index) {
                                        final number = index + 1;

                                        return SimpleDialogOption(
                                          onPressed: () {
                                            Navigator.pop(
                                              dialogContext,
                                              number,
                                            );
                                          },
                                          child: Text('Gambar $number'),
                                        );
                                      }),
                                    );
                                  },
                                );

                                if (!mounted) return;

                                if (imageNumber != null) {
                                  await _fetchPreprocessedImage(imageNumber);
                                }
                              },
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Ambil dari Workstream A'),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isProcessing ? null : _recognizeText,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.document_scanner),
                          label: Text(
                            _isProcessing
                                ? 'Sedang membaca teks...'
                                : 'Mulai OCR',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.text_snippet_outlined,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hasil OCR',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waktu pemrosesan: ${_result!.processingMs} ms',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const Divider(height: 24),
                      SelectableText(
                        _result!.fullText.isEmpty
                            ? 'Tidak ada teks yang terdeteksi.'
                            : _result!.fullText,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Jumlah baris: ${_result!.lines.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _result!.fullText.isEmpty
                              ? null
                              : () {
                                  // Fitur salin teks dapat ditambahkan berikutnya.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Fitur salin akan ditambahkan berikutnya.',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Salin teks'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _exportJson,
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('Ekspor JSON'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'ScanScript • OCR Integration',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
