import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'ocr/mlkit_ocr_engine.dart';
import 'screens/main_shell.dart';
import 'services/preprocessing_gateway.dart';
import 'services/scan_repository.dart';
import 'services/services.dart';
import 'theme/app_theme.dart';

// Diatur lewat: flutter run --dart-define=PREPROCESS_URL=http://<IP>:8002
// Kosong = preprocessing dimatikan (langsung OCR foto asli).
const String _preprocessUrl = String.fromEnvironment('PREPROCESS_URL');
const String _preprocessMethod = String.fromEnvironment(
  'PREPROCESS_METHOD',
  defaultValue: 'contrast_binarization',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();

  Services.init(
    config: config,
    // Workstream B: OCR ML Kit asli (timeout dibaca dari config.json).
    // Workstream A: foto dibersihkan dulu oleh server preprocessing.
    ocr: PreprocessingOcrGateway(
      inner: MlKitOcrEngine(
        timeout: Duration(milliseconds: config.ocrTimeoutMs),
      ),
      serverUrl: _preprocessUrl,
      method: _preprocessMethod,
    ),
    // Penyimpanan tetap menggunakan implementasi bawaan Workspace C.
    repo: JsonFileScanRepository(),
  );

  runApp(const ScanScriptApp());
}

class ScanScriptApp extends StatelessWidget {
  const ScanScriptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanScript',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
