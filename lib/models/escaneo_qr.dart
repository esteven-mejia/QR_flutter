enum TipoQR { url, wifi, texto, contacto }

class EscaneoQR {
  final String id;
  final String contenido;
  final DateTime fechaHora;
  final TipoQR tipo;

  EscaneoQR({
    required this.contenido,
    required this.tipo,
    required this.fechaHora,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Factory constructor para crear desde texto plano
  factory EscaneoQR.fromTexto(String texto) {
    final tipo = texto.startsWith('http')
        ? TipoQR.url
        : texto.startsWith('WIFI:')
            ? TipoQR.wifi
            : TipoQR.texto;
    return EscaneoQR(
      contenido: texto,
      tipo: tipo,
      fechaHora: DateTime.now(),
    );
  }

  /// Convierte el objeto a JSON para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenido': contenido,
      'fechaHora': fechaHora.toIso8601String(),
      'tipo': tipo.name,
    };
  }

  /// Crea un objeto desde JSON
  factory EscaneoQR.fromJson(Map<String, dynamic> json) {
    return EscaneoQR(
      id: json['id'] as String,
      contenido: json['contenido'] as String,
      fechaHora: DateTime.parse(json['fechaHora'] as String),
      tipo: TipoQR.values.firstWhere((e) => e.name == json['tipo']),
    );
  }

  @override
  String toString() {
    final tipoStr = tipo.name.toUpperCase();
    final horaStr = fechaHora.toString().split('.')[0];
    return '[$tipoStr] $contenido\n$horaStr';
  }
}
