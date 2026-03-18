# 🔧 Documentación Técnica - Referencia de Código

## 1. Inicialización del Servicio

### En `main.dart`

```dart
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QRService>(
      future: _inicializarServicio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            // ✅ Servicio inicializado correctamente
            return HomeScreen(service: snapshot.data!);
          }
        }
        // Mientras se inicializa, mostrar loader
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<QRService> _inicializarServicio() async {
    final service = QRService();
    await service.inicializar(); // Carga historial desde SharedPreferences
    return service;
  }
}
```

## 2. Detección y Pausa de Escaneo

### En `scanner_screen.dart`

```dart
void _alDetectar(BarcodeCapture captura) async {
  // Validación: si ya se pausó, ignora
  if (!_escaneandoActivo) return;

  final codigoDetectado = captura.barcodes.firstOrNull?.rawValue;
  if (codigoDetectado == null || codigoDetectado.isEmpty) return;

  // 🔴 PAUSA EL ESCANEO INMEDIATAMENTE
  setState(() => _escaneandoActivo = false);
  await _controlador.stop();

  // Crea objeto y guarda (async)
  final escaneo = EscaneoQR.fromTexto(codigoDetectado);
  await widget.service.agregar(escaneo);

  // Navega a resultado
  if (mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          escaneo: escaneo,
          onVolver: _reanudarEscaneo, // Callback para reactivar
        ),
      ),
    );
  }
}

void _reanudarEscaneo() {
  if (mounted) {
    setState(() => _escaneandoActivo = true);
    _controlador.start(); // 🟢 REACTIVA EL ESCANEO
  }
}
```

## 3. Modelo con Serialización JSON

### En `models/escaneo_qr.dart`

```dart
class EscaneoQR {
  final String id;           // ID único (timestamp)
  final String contenido;    // Contenido del QR
  final DateTime fechaHora;  // Cuándo se escaneó
  final TipoQR tipo;         // Tipo detectado

  EscaneoQR({
    required this.contenido,
    required this.tipo,
    required this.fechaHora,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // 📤 Convertir a JSON para guardar
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenido': contenido,
      'fechaHora': fechaHora.toIso8601String(),
      'tipo': tipo.name,
    };
  }

  // 📥 Crear desde JSON al recuperar
  factory EscaneoQR.fromJson(Map<String, dynamic> json) {
    return EscaneoQR(
      id: json['id'] as String,
      contenido: json['contenido'] as String,
      fechaHora: DateTime.parse(json['fechaHora'] as String),
      tipo: TipoQR.values.firstWhere((e) => e.name == json['tipo']),
    );
  }
}
```

## 4. Servicio con Persistencia

### En `services/qr_service.dart`

```dart
class QRService {
  static const String _key = 'qr_historial';
  final List<EscaneoQR> _historial = [];
  late SharedPreferences _prefs;

  // 🔄 Inicializar: cargar datos del almacenamiento
  Future<void> inicializar() async {
    _prefs = await SharedPreferences.getInstance();
    await _cargarHistorial();
  }

  // 💾 Guardar automáticamente cada vez que se agrega
  Future<void> agregar(EscaneoQR escaneo) async {
    _historial.insert(0, escaneo); // Agregar al principio
    await _guardarHistorial(); // Persiste inmediatamente
  }

  // 🗑️ Eliminar un escaneo específico
  Future<void> eliminarPorId(String id) async {
    _historial.removeWhere((e) => e.id == id);
    await _guardarHistorial();
  }

  // 🔥 Limpiar todo (requiere confirmación)
  Future<void> limpiar() async {
    _historial.clear();
    await _guardarHistorial();
  }

  // 📥 Cargar del almacenamiento
  Future<void> _cargarHistorial() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString != null) {
      try {
        final lista = jsonDecode(jsonString) as List;
        _historial.addAll(
          lista.map((item) => EscaneoQR.fromJson(item as Map<String, dynamic>)),
        );
      } catch (e) {
        // Si hay error, simplemente inicia vacío
        _historial.clear();
      }
    }
  }

  // 📤 Guardar al almacenamiento
  Future<void> _guardarHistorial() async {
    final jsonString = jsonEncode(
      _historial.map((e) => e.toJson()).toList(),
    );
    await _prefs.setString(_key, jsonString);
  }
}
```

## 5. Copiar al Portapapeles

### En `result_screen.dart`

```dart
import 'package:flutter/services.dart';

void _copiarAlPortapapeles(BuildContext context) async {
  // 📋 Copia el contenido
  await Clipboard.setData(
    ClipboardData(text: escaneo.contenido),
  );

  // 📢 Muestra confirmación
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF39A900),
      ),
    );
  }
}
```

## 6. Gestión del Ciclo de Vida

### En `scanner_screen.dart`

```dart
class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    // 👁️ Observar ciclo de vida
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.paused:
        // App va a segundo plano → Pausa escáner (ahorra batería)
        _controlador.stop();
      case AppLifecycleState.resumed:
        // App vuelve al frente → Reactiva si estaba activo
        if (_escaneandoActivo) {
          _controlador.start();
        }
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador.dispose();
    super.dispose();
  }
}
```

## 7. Eliminación de Items con Confirmación

### En `historial_screen.dart`

```dart
void _mostrarConfirmacionEliminar(
  BuildContext context,
  String id,
  String contenido,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar escaneo'),
      content: Text(
        '¿Estás seguro? "$${_truncarTexto(contenido)}"',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            // 🗑️ Elimina de forma asíncrona
            await widget.service.eliminarPorId(id);
            
            if (context.mounted) {
              Navigator.pop(context);
              setState(() {}); // Actualiza pantalla
              
              // 📢 Feedback visual
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Escaneo eliminado'),
                  backgroundColor: Colors.red[700],
                ),
              );
            }
          },
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
```

## 8. Dismiss Gesture para Eliminar

### Listview con deslizar

```dart
Dismissible(
  key: Key(escaneo.id),
  direction: DismissDirection.endToStart, // Deslizar de derecha a izquierda
  onDismissed: (_) async {
    // Elimina sin pedir confirmación (rápido)
    await widget.service.eliminarPorId(escaneo.id);
    setState(() {});
  },
  // Mostrar fondo rojo al deslizar
  background: Container(
    alignment: Alignment.centerRight,
    color: Colors.red[300],
    child: const Icon(Icons.delete),
  ),
  child: ListTile(
    // Contenido del item
  ),
)
```

## 9. Formatos de Fecha Inteligentes

### En `result_screen.dart`

```dart
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
    // Formato completo para fechas antiguas
    final dia = fecha.day;
    final mes = _nombreMes(fecha.month);
    return '$dia de $mes';
  }
}
```

## 10. Detección de Tipo de QR

### En `models/escaneo_qr.dart`

```dart
factory EscaneoQR.fromTexto(String texto) {
  final tipo = texto.startsWith('http')
      ? TipoQR.url              // 🌐 URL/Enlace
      : texto.startsWith('WIFI:')
          ? TipoQR.wifi         // 📡 Red Wi-Fi
          : TipoQR.texto;       // 📝 Texto plano

  // También puede ser detectado como contacto
  if (texto.startsWith('BEGIN:VCARD')) {
    // ... lógica adicional
  }

  return EscaneoQR(
    contenido: texto,
    tipo: tipo,
    fechaHora: DateTime.now(),
  );
}
```

## 📌 Puntos Clave de Implementación

### ✅ Escaneo Único
1. Flag `_escaneandoActivo` controla el estado
2. Se pausa al detectar (evita múltiples detecciones)
3. Se reactiva al aceptar el resultado

### ✅ Persistencia
1. `SharedPreferences` guarda JSON serializado
2. Inicialización async en el `SplashScreen`
3. Cada operación persiste inmediatamente

### ✅ Ciclo de Vida
1. `WidgetsBindingObserver` monitorea estado de app
2. Pausa cámara cuando app va a fondo
3. Reactiva cuando vuelve al frente

### ✅ UX
1. Confirmaciones antes de eliminar
2. Feedback visual (SnackBars)
3. Formatos humanizados
4. Botones claros con iconos

---

## 🎯 Casos de Uso Comunes

### Agregar escaneo desde UI
```dart
final escaneo = EscaneoQR.fromTexto('https://ejemplo.com');
await widget.service.agregar(escaneo);
```

### Cargar historial
```dart
await service.inicializar(); // Carga de SharedPreferences
final items = service.historial;
```

### Eliminar todos
```dart
showDialog(..., onConfirm: () async {
  await widget.service.limpiar();
  setState(() {});
});
```

### Navegar a resultado
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ResultScreen(
      escaneo: escaneo,
      onVolver: () {
        setState(() => _escaneandoActivo = true);
        _controlador.start();
      },
    ),
  ),
);
```

---

¡Toda la lógica está lista para extender y personalizar según tus necesidades!
