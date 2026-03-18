import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scan_app_v2/models/escaneo_qr.dart';
import 'package:qr_scan_app_v2/services/qr_service.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  final QRService service;
  const ScannerScreen({super.key, required this.service});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late MobileScannerController _controlador;
  bool _escaneandoActivo = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controlador = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.paused:
        _controlador.stop();
        break;
      case AppLifecycleState.resumed:
        if (_escaneandoActivo) {
          _controlador.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Maneja la detección de códigos QR
  void _alDetectar(BarcodeCapture captura) async {
    // Si ya se pausó el escaneo (por un escaneo anterior), ignora
    if (!_escaneandoActivo) return;

    final codigoDetectado = captura.barcodes.firstOrNull?.rawValue;
    if (codigoDetectado == null || codigoDetectado.isEmpty) return;

    // Pausa el escaneo inmediatamente
    setState(() => _escaneandoActivo = false);
    await _controlador.stop();

    // Crea el objeto de escaneo y lo agrega al servicio
    final escaneo = EscaneoQR.fromTexto(codigoDetectado);
    await widget.service.agregar(escaneo);

    // Navega a la pantalla de resultado
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            escaneo: escaneo,
            onVolver: _reanudarEscaneo,
          ),
        ),
      );
    }
  }

  /// Reanuda el escaneo cuando regresa de la pantalla de resultado
  void _reanudarEscaneo() {
    if (mounted) {
      setState(() => _escaneandoActivo = true);
      _controlador.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner QR'),
        backgroundColor: const Color(0xFF39A900),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Área del escáner
          if (_escaneandoActivo)
            MobileScanner(
              controller: _controlador,
              onDetect: _alDetectar,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al acceder a la cámara',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_bottom,
                      color: Color(0xFF39A900),
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Procesando escaneo...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Overlay con instrucciones
          if (_escaneandoActivo)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Apunta el código QR hacia la cámara',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
