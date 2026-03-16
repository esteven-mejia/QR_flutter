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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Una sola instancia del servicio compartida entre pantallas
  final QRService _service = QRService();
  int _paginaActual = 0;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      ScannerScreen(service: _service),
      HistorialScreen(service: _service),
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
