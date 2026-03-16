import 'package:qr_scan_app_v2/models/escaneo_qr.dart';

class QRService {
  final List<EscaneoQR> _historial = [];
  List<EscaneoQR> get historial => List.unmodifiable(_historial);
  int get total => _historial.length;
  void agregar(EscaneoQR e) => _historial.insert(0, e);
  void limpiar() => _historial.clear();
}
