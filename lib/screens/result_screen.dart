import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_scan_app_v2/models/escaneo_qr.dart';
import 'package:qr_scan_app_v2/services/url_launcher_service.dart';
import 'package:qr_scan_app_v2/screens/web_view_screen.dart';

class ResultScreen extends StatelessWidget {
  final EscaneoQR escaneo;
  final VoidCallback onVolver;

  const ResultScreen({
    super.key,
    required this.escaneo,
    required this.onVolver,
  });

  /// Copia el contenido al portapapeles y muestra una notificación
  void _copiarAlPortapapeles(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: escaneo.contenido),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copiado al portapapeles'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF39A900),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Regresa a la pantalla del escáner y lo reactiva
  void _aceptarYVolver(BuildContext context) {
    final esUrl = escaneo.tipo == TipoQR.url;

    if (esUrl) {
      // Si es URL, mostrar opciones de navegación
      _mostrarOpcionesNavegacion(context);
    } else {
      // Si no es URL, simplemente volver
      Navigator.pop(context);
      onVolver();
    }
  }

  /// Muestra un dialogo con opciones para abrir la URL
  void _mostrarOpcionesNavegacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir enlace'),
        content: Text(
          '¿Cómo deseas abrir este enlace?\n\n${URLLauncherService.obtenerDominio(escaneo.contenido)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _abrirEnWebView(context);
            },
            child: const Text(
              'Abrir en app',
              style: TextStyle(color: Color(0xFF39A900)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _abrirEnNavegador(context);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Navegador'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39A900),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Abre la URL en el WebView integrado de la app
  Future<void> _abrirEnWebView(BuildContext context) async {
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: escaneo.contenido,
            titulo: URLLauncherService.obtenerDominio(escaneo.contenido),
          ),
        ),
      );
      // Después de cerrar el WebView, cerrar el ResultScreen y reactivar escáner
      if (context.mounted) {
        Navigator.pop(context);
        onVolver();
      }
    }
  }

  /// Abre la URL en el navegador externo del dispositivo
  Future<void> _abrirEnNavegador(BuildContext context) async {
    final url = escaneo.contenido;

    // Mostrar un indicador de carga
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abriendo navegador...'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF39A900),
        ),
      );
    }

    // Intentar abrir la URL
    final seAbrio = await URLLauncherService.abrirUrlEnNavegador(url);

    if (!seAbrio && context.mounted) {
      // Mostrar error si no se pudo abrir
      _mostrarErrorAlAbrirUrl(context, url);
    } else if (context.mounted) {
      // Cerrar el ResultScreen y reactivar escáner
      Navigator.pop(context);
      onVolver();
    }
  }

  /// Muestra un dialogo de error si no se puede abrir la URL
  void _mostrarErrorAlAbrirUrl(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(
          'No se pudo abrir el enlace:\n\n$url\n\nVerifica que la URL es válida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Retorna un icono según el tipo de QR
  IconData _obtenerIconoTipo() {
    switch (escaneo.tipo) {
      case TipoQR.url:
        return Icons.link;
      case TipoQR.wifi:
        return Icons.wifi;
      case TipoQR.contacto:
        return Icons.contacts;
      default:
        return Icons.text_fields;
    }
  }

  /// Retorna una etiqueta según el tipo de QR
  String _obtenerEtiqueta() {
    switch (escaneo.tipo) {
      case TipoQR.url:
        return 'Enlace (URL)';
      case TipoQR.wifi:
        return 'Wi-Fi';
      case TipoQR.contacto:
        return 'Contacto';
      default:
        return 'Texto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del Escaneo'),
        backgroundColor: const Color(0xFF39A900),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta principal con información del QR
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de QR
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF39A900).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _obtenerIconoTipo(),
                              color: const Color(0xFF39A900),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tipo de código',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  _obtenerEtiqueta(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      // Contenido del QR
                      Text(
                        'Contenido',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        escaneo.contenido,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      // Fecha y hora
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Escaneado',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  _formatearFecha(escaneo.fechaHora),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Botones de acción
              Row(
                children: [
                  // Botón Copiar
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _copiarAlPortapapeles(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón Aceptar (cambia según el tipo de QR)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aceptarYVolver(context),
                      icon: Icon(
                        escaneo.tipo == TipoQR.url
                            ? Icons.open_in_new
                            : Icons.check_circle,
                      ),
                      label: Text(
                        escaneo.tipo == TipoQR.url ? 'Abrir' : 'Aceptar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39A900),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botón Volver (alternativa)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onVolver();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFF39A900),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Volver',
                    style: TextStyle(
                      color: Color(0xFF39A900),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatea la fecha y hora de manera legible
  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minuto(s)';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} hora(s)';
    } else {
      final dia = fecha.day;
      final mes = _nombreMes(fecha.month);
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      return '$dia de $mes a las $hora:$minuto';
    }
  }

  /// Retorna el nombre del mes
  String _nombreMes(int mes) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return meses[mes - 1];
  }
}
