enum TipoQR { url, wifi, texto, contacto }

class EscaneoQR {
  final String contenido;
  final DateTime fechaHora;
  final TipoQR tipo;
  EscaneoQR({required this.contenido, required this.tipo})
    : fechaHora = DateTime.now();
  
  // Factory constructor
  factory EscaneoQR.fromTexto(String texto) {
    final tipo = texto.startsWith('http')
        ? TipoQR.url
        : texto.startsWith('WIFI:')
        ? TipoQR.wifi
        : TipoQR.texto;
    return EscaneoQR(contenido: texto, tipo: tipo);
  }
  @override
  String toString() => '[' + tipo.name.toUpperCase() + '] ' + contenido;
}
