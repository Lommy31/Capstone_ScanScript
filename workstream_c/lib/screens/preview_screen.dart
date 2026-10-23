import 'dart:io';

import 'package:flutter/material.dart';

import '../services/services.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _processing = false;

  Future<void> _scan() async {
    if (_processing) return;
    setState(() => _processing = true);

    // SafeOcrGateway sudah menangani timeout/error, jadi di sini tidak
    // akan pernah throw dan tidak akan menggantung lebih dari timeout config.
    final result = await Services.ocr.recognize(
      imagePath: widget.imagePath,
      imageId: DateTime.now().microsecondsSinceEpoch.toString(),
    );

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            ResultScreen.fromOcr(imagePath: widget.imagePath, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pratinjau')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(8),
                  decoration: AppDecor.card(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('Gambar tidak bisa ditampilkan.'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    if (_processing) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _processing ? null : _scan,
                        icon: _processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.document_scanner),
                        label: Text(
                          _processing
                              ? 'Sedang membaca teks...'
                              : 'Pindai teks',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
