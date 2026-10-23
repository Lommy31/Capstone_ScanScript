import '../config/app_config.dart';
import 'export_service.dart';
import 'ocr_gateway.dart';
import 'scan_repository.dart';

/// Tempat satu-satunya merakit dependensi. Saat integrasi, workstream lain
/// cukup mengganti isi init() di main.dart:
///   - B: ganti [ocr] dengan gateway berbasis engine asli
///   - D: ganti [repo] dengan implementasi SQLite
class Services {
  Services._();

  static late AppConfig config;
  static late OcrGateway ocr;
  static late ScanRepository repo;
  static late ExportService export;

  static void init({
    required AppConfig config,
    required OcrGateway ocr,
    required ScanRepository repo,
    ExportService export = const ExportService(),
  }) {
    Services.config = config;
    Services.ocr = SafeOcrGateway(inner: ocr, config: config);
    Services.repo = repo;
    Services.export = export;
  }
}
