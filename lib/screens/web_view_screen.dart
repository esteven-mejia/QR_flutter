import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String titulo;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.titulo,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controlador;
  int _progreso = 0;
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _inicializarWebView();
  }

  /// Inicializa el controlador del WebView
  void _inicializarWebView() {
    // Configurar el controlador del WebView
    _controlador = WebViewController()
      // Habilitar JavaScript
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Callback para cambios de progreso de carga
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _estaCargando = true);
          },
          onProgress: (int progress) {
            setState(() => _progreso = progress);
          },
          onPageFinished: (String url) {
            setState(() {
              _estaCargando = false;
              _progreso = 100;
            });
          },
          // Manejo de errores
          onWebResourceError: (WebResourceError error) {
            _mostrarErrorSnackBar(
              'Error al cargar la página: ${error.description}',
            );
          },
          // Manejo de rutas (para permitir navegación dentro del sitio)
          onNavigationRequest: (NavigationRequest request) {
            // Permitir que se carguen las páginas dentro del sitio
            return NavigationDecision.navigate;
          },
        ),
      )
      // Cargar la URL
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Muestra un error en un SnackBar
  void _mostrarErrorSnackBar(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Recarga la página
  void _recargar() {
    _controlador.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titulo,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF39A900),
        elevation: 0,
        actions: [
          // Botón recargar
          Tooltip(
            message: 'Recargar',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _recargar,
            ),
          ),
          // Botón abrir en navegador externo
          Tooltip(
            message: 'Abrir en navegador',
            child: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                // Aquí se podría abrir en navegador externo
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controlador),

          // Indicador de progreso
          if (_estaCargando)
            LinearProgressIndicator(
              value: _progreso / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF39A900)),
            ),
        ],
      ),
    );
  }
}
