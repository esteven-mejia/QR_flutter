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
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Contenido copiado'),
            ],
          ),
          duration: const Duration(seconds: 2),
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
            child: Text(
              'Abrir en app',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _abrirEnNavegador(context);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Navegador'),
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
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Abriendo navegador...'),
            ],
          ),
          duration: Duration(seconds: 3),
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
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(
          'No se pudo abrir el enlace:\n\n$url\n\nVerifica que la URL es válida.',
        ),
        actions: [
          ElevatedButton(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del Escaneo'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            onVolver();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta principal con información del QR
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo de QR con icono
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _obtenerIconoTipo(),
                            color: primaryColor,
                            size: 32,
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
                                    .labelSmall
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _obtenerEtiqueta(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: isDark
                          ? Colors.grey[700]
                          : Colors.grey[200],
                    ),
                    const SizedBox(height: 24),
                    // Contenido del QR
                    Text(
                      'Contenido',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: SelectableText(
                        escaneo.contenido,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontSize: 15,
                              height: 1.6,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: isDark
                          ? Colors.grey[700]
                          : Colors.grey[200],
                    ),
                    const SizedBox(height: 24),
                    // Fecha y hora
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Escaneado',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatearFecha(escaneo.fechaHora),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
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
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Botón principal de acción
                  ElevatedButton.icon(
                    onPressed: () => _aceptarYVolver(context),
                    icon: Icon(
                      escaneo.tipo == TipoQR.url
                          ? Icons.open_in_new
                          : Icons.check_circle,
                    ),
                    label: Text(
                      escaneo.tipo == TipoQR.url ? 'Abrir enlace' : 'Aceptar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botón Copiar
                  OutlinedButton.icon(
                    onPressed: () => _copiarAlPortapapeles(context),
                    icon: const Icon(Icons.copy),
                    label: const Text(
                      'Copiar contenido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botón Volver
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onVolver();
                    },
                    child: Text(
                      'Escanear otro código',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
