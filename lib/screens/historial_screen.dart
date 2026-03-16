import 'package:flutter/material.dart';
import 'package:qr_scan_app_v2/services/qr_service.dart';

class HistorialScreen extends StatelessWidget {
  final QRService service;
  const HistorialScreen({super.key, required this.service});
  @override
  Widget build(BuildContext context) {
    final items = service.historial;
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial (' + service.total.toString() + ')'),
        backgroundColor: const Color(0xFF39A900),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Sin escaneos aún'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final e = items[i];
                return ListTile(
                  leading: const Icon(Icons.qr_code, color: Color(0xFF39A900)),
                  title: Text(e.contenido, overflow: TextOverflow.ellipsis),
                  subtitle: Text(e.toString()),
                );
              },
            ),
    );
  }
}
