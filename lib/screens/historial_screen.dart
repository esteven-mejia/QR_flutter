import 'package:flutter/material.dart';
import 'package:qr_scan_app_v2/services/qr_service.dart';

class HistorialScreen extends StatefulWidget {
  final QRService service;

  const HistorialScreen({super.key, required this.service});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  /// Muestra un menú con opciones para el escaneo
  void _mostrarMenuOpciones(BuildContext context, dynamic escaneo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _mostrarConfirmacionEliminar(
                  context,
                  escaneo.id,
                  escaneo.contenido,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación para eliminar un escaneo
  void _mostrarConfirmacionEliminar(
    BuildContext context,
    String id,
    String contenido,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar escaneo'),
        content: Text(
          '¿Estás seguro de que deseas eliminar este escaneo?\n\n"${contenido.length > 50 ? '${contenido.substring(0, 50)}...' : contenido}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await widget.service.eliminarPorId(id);
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(dialogContext);
              setState(() {});
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Escaneo eliminado'),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de confirmación para limpiar todo el historial
  void _mostrarConfirmacionLimpiar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar TODOS los escaneos? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await widget.service.limpiar();
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Historial eliminado completamente'),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar todo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.service.historial;

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial (${widget.service.total})'),
        backgroundColor: const Color(0xFF39A900),
        elevation: 0,
        actions: [
          // Botón para limpiar todo el historial
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: 'Limpiar historial completo',
                child: IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _mostrarConfirmacionLimpiar(context),
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin escaneos aún',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escanea códigos QR para verlos aquí',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final escaneo = items[i];
                final tipoColor = _obtenerColorPorTipo(escaneo.tipo);
                final tipoIcono = _obtenerIconoPorTipo(escaneo.tipo);

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Dismissible(
                    key: Key(escaneo.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) async {
                      await widget.service.eliminarPorId(escaneo.id);
                      if (mounted) {
                        setState(() {});
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Escaneo eliminado'),
                            backgroundColor: Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Colors.red[300],
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    child: Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tipoColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            tipoIcono,
                            color: tipoColor,
                          ),
                        ),
                        title: Text(
                          escaneo.contenido,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _formatearFecha(escaneo.fechaHora),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: SizedBox(
                          width: 58,
                          child: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _mostrarMenuOpciones(
                              context,
                              escaneo,
                            ),
                            tooltip: 'Opciones',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Retorna el color según el tipo de QR
  Color _obtenerColorPorTipo(dynamic tipo) {
    switch (tipo.toString()) {
      case 'TipoQR.url':
        return Colors.blue;
      case 'TipoQR.wifi':
        return Colors.purple;
      case 'TipoQR.contacto':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Retorna el icono según el tipo de QR
  IconData _obtenerIconoPorTipo(dynamic tipo) {
    switch (tipo.toString()) {
      case 'TipoQR.url':
        return Icons.link;
      case 'TipoQR.wifi':
        return Icons.wifi;
      case 'TipoQR.contacto':
        return Icons.contacts;
      default:
        return Icons.text_fields;
    }
  }

  /// Formatea la fecha de manera corta
  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes}m';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays}d';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
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

