import '../services/ocr_gateway.dart';

/// Engine OCR (Workstream B). Meng-implement [OcrGateway] supaya engine bisa
/// langsung didaftarkan di Services.init() tanpa kelas adapter tambahan.
/// Mau tukar ke Tesseract nanti? Cukup bikin kelas lain yang implement ini.
abstract class OcrEngine implements OcrGateway {
  Future<void> close();
}
