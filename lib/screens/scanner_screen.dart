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
  bool _linternaPrendida = false;

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

  /// Cambia el estado de la linterna
  void _toggleLinterna() {
    setState(() {
      _linternaPrendida = !_linternaPrendida;
      _controlador.toggleTorch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Área del escáner
          if (_escaneandoActivo)
            MobileScanner(
              controller: _controlador,
              onDetect: _alDetectar,
              errorBuilder: (context, error, child) {
                return Container(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Error al acceder a la cámara',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Verifica los permisos de cámara en la configuración',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Container(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Procesando escaneo...',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          // Overlay con instrucciones
          if (_escaneandoActivo)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Posiciona el código QR frente a la cámara',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Botones de control
          if (_escaneandoActivo)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        onPressed: _toggleLinterna,
                        mini: true,
                        backgroundColor: _linternaPrendida
                            ? Colors.amber.withValues(alpha: 0.9)
                            : Colors.black54,
                        tooltip: _linternaPrendida ? 'Apagar linterna' : 'Encender linterna',
                        child: Icon(
                          _linternaPrendida ? Icons.flashlight_on : Icons.flashlight_off,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
