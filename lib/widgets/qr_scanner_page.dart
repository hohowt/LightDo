import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/sync_service.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key, required this.syncService});

  final SyncService syncService;

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _syncing = false;
  String? _error;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_syncing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.scheme.startsWith('ws')) return;
    final token = uri.queryParameters['token'];
    if (token == null) return;

    setState(() {
      _syncing = true;
      _error = null;
    });

    try {
      final wsUrl = '${uri.scheme}://${uri.host}:${uri.port}${uri.path}';
      await widget.syncService.connectToServer(wsUrl, token);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _error = '连接失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描同步码')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_syncing)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('正在连接…'),
                    ],
                  ),
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Card(
                color: const Color(0xFFFFEBEE),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFC62828)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
