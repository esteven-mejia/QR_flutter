import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scan_app_v2/models/escaneo_qr.dart';
import 'package:qr_scan_app_v2/services/qr_service.dart';

class ScannerScreen extends StatefulWidget {
  final QRService service;
  const ScannerScreen({super.key, required this.service});
  @override
  State<ScannerScreen> createState() => _ScannerState();
}

class _ScannerState extends State<ScannerScreen> {
  final _ctrl = MobileScannerController();
  String _ultimo = 'Sin escanear';
  void _detectar(BarcodeCapture cap) {
    final raw = cap.barcodes.first.rawValue;
    if (raw != null) {
      widget.service.agregar(EscaneoQR.fromTexto(raw));
      setState(() => _ultimo = raw);
    }
  }

  @override
  Widget build(BuildContext ctx) => Column(
    children: [
      Expanded(
        child: MobileScanner(controller: _ctrl, onDetect: _detectar),
      ),
      Text(_ultimo),
    ],
  );
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
