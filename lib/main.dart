import 'package:flutter/material.dart';
import 'services/qr_service.dart';
import 'screens/scanner_screen.dart';
import 'screens/historial_screen.dart';

void main() {
  runApp(const QRScanApp());
}

class QRScanApp extends StatelessWidget {
  const QRScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner QR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF39A900)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Pantalla de splash que inicializa el servicio
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QRService>(
      future: _inicializarServicio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return HomeScreen(service: snapshot.data!);
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Error al inicializar la aplicación'),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString()),
                  ],
                ),
              ),
            );
          }
        }
        // Mientras se está inicializando
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF39A900)),
                ),
                const SizedBox(height: 16),
                const Text('Inicializando aplicación...'),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Inicializa el servicio QR
  Future<QRService> _inicializarServicio() async {
    final service = QRService();
    await service.inicializar();
    return service;
  }
}

class HomeScreen extends StatefulWidget {
  final QRService service;

  const HomeScreen({super.key, required this.service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _paginaActual = 0;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      ScannerScreen(service: widget.service),
      HistorialScreen(service: widget.service),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escáner QR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF39A900),
        foregroundColor: Colors.white,
      ),
      body: paginas[_paginaActual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _paginaActual,
        onDestinationSelected: (i) => setState(() => _paginaActual = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Escanear',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}
