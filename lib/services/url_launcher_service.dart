import 'package:url_launcher/url_launcher.dart';

/// Servicio para manejar la apertura de URLs en el navegador
class URLLauncherService {
  /// Verifica si una cadena es una URL válida
  static bool esUrlValida(String texto) {
    try {
      final uri = Uri.parse(texto);
      // Verificar que tiene scheme (http/https) o que comienza con www.
      return uri.scheme == 'http' ||
          uri.scheme == 'https' ||
          texto.startsWith('www.');
    } catch (e) {
      return false;
    }
  }

  /// Formatea una URL asegurando que tenga scheme válido
  static String formatearUrl(String url) {
    String urlFormateada = url.trim();

    // Si comienza con www. pero no tiene scheme, agregar https://
    if (urlFormateada.startsWith('www.') && !urlFormateada.startsWith('http')) {
      urlFormateada = 'https://$urlFormateada';
    }

    // Si no tiene scheme, asumir https://
    if (!urlFormateada.startsWith('http://') &&
        !urlFormateada.startsWith('https://')) {
      urlFormateada = 'https://$urlFormateada';
    }

    return urlFormateada;
  }

  /// Abre una URL en el navegador del dispositivo
  /// Retorna true si se abrió exitosamente, false en caso contrario
  static Future<bool> abrirUrlEnNavegador(String url) async {
    try {
      final urlFormateada = formatearUrl(url);
      final uri = Uri.parse(urlFormateada);

      // Verificar si se puede lanzar la URL
      if (await canLaunchUrl(uri)) {
        // Lanzar en el navegador predeterminado del dispositivo
        final resultado = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Abre en navegador externo
        );
        return resultado;
      } else {
        // No se puede lanzar
        return false;
      }
    } catch (e) {
      // Error al intentar abrir la URL
      return false;
    }
  }

  /// Abre un correo electrónico
  static Future<bool> abrirCorreo(String correo) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: correo,
      );

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Abre una llamada telefónica
  static Future<bool> abrirTelefono(String numero) async {
    try {
      final uri = Uri(
        scheme: 'tel',
        path: numero,
      );

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el dominio de una URL
  static String obtenerDominio(String url) {
    try {
      final urlFormateada = formatearUrl(url);
      final uri = Uri.parse(urlFormateada);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// Verifica si es un correo electrónico
  static bool esCorreo(String texto) {
    final RegExp regex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(texto);
  }

  /// Verifica si es un número de teléfono
  static bool esTelefono(String texto) {
    final RegExp regex = RegExp(r'^[\d\s\-\(\)\+]{7,}$');
    return regex.hasMatch(texto);
  }
}
