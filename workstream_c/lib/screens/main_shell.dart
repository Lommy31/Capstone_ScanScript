import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/services.dart';
import '../widgets/app_widgets.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'scan_launcher.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    try {
      final list = await Services.repo.list();
      if (mounted) setState(() => _count = list.length);
    } catch (_) {}
  }

  Future<void> _camera() async {
    await ScanLauncher.pick(context, ImageSource.camera);
    _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FC),
      // Tanpa IndexedStack: Riwayat dibuat ulang tiap dibuka, jadi selalu fresh.
      body: _index == 0
          ? HomeScreen(onReturn: _refreshCount)
          : HistoryScreen(onChanged: _refreshCount),
      bottomNavigationBar: AppNavBar(
        index: _index,
        historyCount: _count,
        onCamera: _camera,
        onChanged: (i) {
          setState(() => _index = i);
          _refreshCount();
        },
      ),
    );
  }
}
