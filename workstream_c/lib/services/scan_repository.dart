import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/scan_record.dart';

/// Kontrak penyimpanan untuk UI. Workstream D tinggal bikin implementasi
/// SQLite (sqflite/Room) dan menggantinya di main.dart tanpa menyentuh UI.
abstract class ScanRepository {
  Future<List<ScanRecord>> list(); // terbaru dulu
  Future<void> save(ScanRecord record); // insert atau update berdasarkan id
  Future<void> delete(String id);
}

/// Implementasi sementara: satu file JSON di folder dokumen app.
class JsonFileScanRepository implements ScanRepository {
  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/scan_history.json');
    return _file!;
  }

  Future<List<ScanRecord>> _readAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => ScanRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // File korup -> jangan bikin app crash, mulai dari kosong.
      return [];
    }
  }

  Future<void> _writeAll(List<ScanRecord> records) async {
    final file = await _getFile();
    await file.writeAsString(
      jsonEncode(records.map((r) => r.toJson()).toList()),
      flush: true,
    );
  }

  @override
  Future<List<ScanRecord>> list() async {
    final all = await _readAll();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Future<void> save(ScanRecord record) async {
    final all = await _readAll();
    final i = all.indexWhere((r) => r.id == record.id);
    if (i >= 0) {
      all[i] = record;
    } else {
      all.add(record);
    }
    await _writeAll(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = await _readAll();
    all.removeWhere((r) => r.id == id);
    await _writeAll(all);
  }
}
