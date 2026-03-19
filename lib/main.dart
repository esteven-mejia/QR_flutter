import 'package:flutter/material.dart';
import 'services/qr_service.dart';
import 'screens/scanner_screen.dart';
import 'screens/historial_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const QRScanApp());
}

class QRScanApp extends StatefulWidget {
  const QRScanApp({super.key});

  @override
  State<QRScanApp> createState() => _QRScanAppState();
}

class _QRScanAppState extends State<QRScanApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner QR Profesional',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: SplashScreen(onThemeChanged: _toggleTheme, currentTheme: _themeMode),
    );
  }
}

/// Pantalla de splash que inicializa el servicio
class SplashScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const SplashScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QRService>(
      future: _inicializarServicio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return HomeScreen(
              service: snapshot.data!,
              onThemeChanged: onThemeChanged,
              currentTheme: currentTheme,
            );
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
                  valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Inicializando aplicación...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const HomeScreen({
    super.key,
    required this.service,
    required this.onThemeChanged,
    required this.currentTheme,
  });

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
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PopupMenuButton<ThemeMode>(
              initialValue: widget.currentTheme,
              onSelected: (ThemeMode mode) {
                widget.onThemeChanged(mode);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(Icons.light_mode, size: 20),
                      SizedBox(width: 12),
                      Text('Tema claro'),
                    ],
                  ),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(Icons.dark_mode, size: 20),
                      SizedBox(width: 12),
                      Text('Tema oscuro'),
                    ],
                  ),
                ),
                const PopupMenuItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(Icons.brightness_auto, size: 20),
                      SizedBox(width: 12),
                      Text('Sistema'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.brightness_4),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: paginas[_paginaActual],
      ),
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
