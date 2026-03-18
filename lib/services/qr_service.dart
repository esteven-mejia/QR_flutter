import 'package:qr_scan_app_v2/models/escaneo_qr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QRService {
  static const String _key = 'qr_historial';
  final List<EscaneoQR> _historial = [];
  late SharedPreferences _prefs;
  bool _inicializado = false;

  /// Inicializa el servicio cargando el historial desde almacenamiento local
  Future<void> inicializar() async {
    if (_inicializado) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _cargarHistorial();
    _inicializado = true;
  }

  /// Carga el historial desde SharedPreferences
  Future<void> _cargarHistorial() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString != null) {
      try {
        final lista = jsonDecode(jsonString) as List;
        _historial.clear();
        _historial.addAll(
          lista.map((item) => EscaneoQR.fromJson(item as Map<String, dynamic>)),
        );
      } catch (e) {
        // Si hay error al decodificar, simplemente limpiamos
        _historial.clear();
      }
    }
  }

  /// Guarda el historial en SharedPreferences
  Future<void> _guardarHistorial() async {
    final jsonString = jsonEncode(
      _historial.map((e) => e.toJson()).toList(),
    );
    await _prefs.setString(_key, jsonString);
  }

  /// Obtiene el historial actual (no modificable)
  List<EscaneoQR> get historial => List.unmodifiable(_historial);
  
  /// Obtiene la cantidad total de escaneos
  int get total => _historial.length;

  /// Agrega un nuevo escaneo al principio del historial y lo guarda
  Future<void> agregar(EscaneoQR escaneo) async {
    _historial.insert(0, escaneo);
    await _guardarHistorial();
  }

  /// Elimina un escaneo específico por su ID
  Future<void> eliminarPorId(String id) async {
    _historial.removeWhere((e) => e.id == id);
    await _guardarHistorial();
  }

  /// Limpia todo el historial
  Future<void> limpiar() async {
    _historial.clear();
    await _guardarHistorial();
  }
}
