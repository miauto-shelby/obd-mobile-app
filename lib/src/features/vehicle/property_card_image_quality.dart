import 'dart:typed_data';

import 'package:image/image.dart' as image;

class PropertyCardImageQuality {
  const PropertyCardImageQuality._();

  /// Returns a user-facing suggestion without retaining the image or its data.
  static String? evaluate(Uint8List bytes) {
    final decoded = image.decodeImage(bytes);
    if (decoded == null) return 'No pudimos revisar la calidad de la imagen.';
    if (decoded.width < 900 || decoded.height < 600) {
      return 'La imagen tiene poca resolución. Acerca la tarjeta y vuelve a intentarlo para leer más datos.';
    }

    var samples = 0;
    var total = 0.0;
    var totalSquared = 0.0;
    final stepX = (decoded.width / 32).ceil();
    final stepY = (decoded.height / 32).ceil();
    for (var y = 0; y < decoded.height; y += stepY) {
      for (var x = 0; x < decoded.width; x += stepX) {
        final pixel = decoded.getPixel(x, y);
        final luminance =
            0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
        total += luminance;
        totalSquared += luminance * luminance;
        samples++;
      }
    }
    final average = total / samples;
    final contrast = (totalSquared / samples - average * average).clamp(
      0,
      double.infinity,
    );
    if (average < 55) {
      return 'La foto está oscura. Busca más luz antes de volver a leer la tarjeta.';
    }
    if (average > 225) {
      return 'La foto tiene mucho brillo o reflejo. Inclina la tarjeta y evita el flash directo.';
    }
    if (contrast < 260) {
      return 'El texto tiene poco contraste. Acerca la tarjeta, evita reflejos y procura un fondo uniforme.';
    }
    return null;
  }
}
