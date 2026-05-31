import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';

class QrScannerWidget extends StatefulWidget {
  final void Function(String codigo) onDetected;
  final String titulo;

  const QrScannerWidget({
    super.key,
    required this.onDetected,
    this.titulo = 'Escanear código QR',
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  late MobileScannerController _controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _scanned = true;
                Navigator.pop(context);
                widget.onDetected(barcode!.rawValue!);
              }
            },
          ),
          // Overlay con visor
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.accentColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Apunta la cámara al código QR',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Función helper para abrir el scanner desde cualquier pantalla
Future<String?> abrirEscaner(BuildContext context, {String titulo = 'Escanear QR'}) async {
  String? resultado;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QrScannerWidget(
        titulo: titulo,
        onDetected: (codigo) {
          resultado = codigo;
        },
      ),
    ),
  );
  return resultado;
}