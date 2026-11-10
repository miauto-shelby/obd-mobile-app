import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image;

/// A locally generated proposal. It is never sent to the backend as an image.
class PropertyCardOcrDraft {
  const PropertyCardOcrDraft({
    this.plate,
    this.vin,
    this.brand,
    this.model,
    this.year,
    this.engine,
    this.fuelType,
    this.detectedFields = 0,
  });

  final String? plate;
  final String? vin;
  final String? brand;
  final String? model;
  final String? year;
  final String? engine;
  final String? fuelType;
  final int detectedFields;

  bool get hasUsefulData => detectedFields > 0;
}

class PropertyCardOcrService {
  Future<PropertyCardOcrDraft> read({
    required String imagePath,
    required List<String> activeBrands,
  }) async {
    final sourceBytes = await File(imagePath).readAsBytes();
    final decoded = image.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('La imagen no pudo ser procesada.');
    }
    final normalized = image.bakeOrientation(decoded);
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'my_auto_ocr_',
    );
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      PropertyCardOcrDraft? bestDraft;
      var bestScore = -1;
      for (final rotation in const [0, 90, 180, 270]) {
        final candidate = rotation == 0
            ? normalized
            : image.copyRotate(normalized, angle: rotation);
        final candidateFile = File(
          '${temporaryDirectory.path}${Platform.pathSeparator}$rotation.jpg',
        );
        await candidateFile.writeAsBytes(
          image.encodeJpg(candidate, quality: 88),
        );
        final result = await recognizer.processImage(
          InputImage.fromFilePath(candidateFile.path),
        );
        final draft = PropertyCardOcrParser.parseRecognized(
          rawText: result.text,
          lines: result.blocks
              .expand(
                (block) => block.lines.map(
                  (line) => PropertyCardOcrLine(
                    text: line.text,
                    left: line.boundingBox.left,
                    top: line.boundingBox.top,
                    right: line.boundingBox.right,
                    bottom: line.boundingBox.bottom,
                  ),
                ),
              )
              .toList(),
          activeBrands: activeBrands,
        );
        final score = draft.detectedFields;
        if (score > bestScore) {
          bestScore = score;
          bestDraft = draft;
        }
        if (kDebugMode) {
          debugPrint(
            '[OCR] rotation=$rotation fields=$score lines=${result.blocks.expand((block) => block.lines).length}',
          );
        }
      }
      return bestDraft!;
    } finally {
      await recognizer.close();
      await temporaryDirectory.delete(recursive: true);
    }
  }
}

class PropertyCardOcrLine {
  const PropertyCardOcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}

class PropertyCardOcrParser {
  static final _vinPattern = RegExp(
    r'(?<![A-Z0-9])[A-HJ-NPR-Z0-9]{17}(?![A-Z0-9])',
  );
  static final _platePattern = RegExp(
    r'(?<![A-Z0-9])(?:[A-Z]{3}[0-9]{3}|[A-Z]{3}[0-9]{2}[A-Z])(?![A-Z0-9])',
  );
  static final _yearPattern = RegExp(r'(?<![0-9])(?:19|20)[0-9]{2}(?![0-9])');

  static PropertyCardOcrDraft parse(
    String rawText, {
    required List<String> activeBrands,
  }) {
    final lines = rawText
        .toUpperCase()
        .split(RegExp(r'\r?\n'))
        .map(_normalize)
        .where((line) => line.isNotEmpty)
        .toList();
    final text = lines.join(' ');

    final plate = _platePattern.firstMatch(text)?.group(0);
    final vin = _vinNearLabel(lines);
    final brand = _findBrand(text, activeBrands);
    final model = _modelNearLabel(lines);
    final year = _yearNearLabel(lines);
    final engine = _engineNearLabel(lines);

    final values = [plate, vin, brand, model, year, engine];
    return PropertyCardOcrDraft(
      plate: plate,
      vin: vin,
      brand: brand,
      model: model,
      year: year,
      engine: engine,
      detectedFields: values
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .length,
    );
  }

  /// Uses the position of text lines in a Colombian transit licence. Distances
  /// are rotation-independent, so a sideways photo does not change the match.
  static PropertyCardOcrDraft parseRecognized({
    required String rawText,
    required List<PropertyCardOcrLine> lines,
    required List<String> activeBrands,
  }) {
    final fallback = parse(rawText, activeBrands: activeBrands);
    final normalizedLines = lines
        .map((line) => _PositionedLine(line, _normalize(line.text)))
        .where((line) => line.value.isNotEmpty)
        .toList();

    final model =
        _nearestValue(normalizedLines, const [
          'LINEA',
          'LÍNEA',
        ], _isTrustedModel) ??
        _modelForBrand(normalizedLines, fallback.brand);
    final yearCandidate = _nearestValue(normalizedLines, const [
      'MODELO',
      'ANO',
      'AÑO',
    ], (value) => _yearPattern.hasMatch(value));
    final year = yearCandidate == null
        ? null
        : _yearPattern.firstMatch(yearCandidate)?.group(0);
    final vinCandidate = _nearestValue(normalizedLines, const [
      'VIN',
      'NIV',
    ], (value) => _vinPattern.hasMatch(value));
    final vin =
        _vinPattern.firstMatch(vinCandidate ?? '')?.group(0) ?? fallback.vin;
    final engine =
        _formatEngine(
          _nearestValue(normalizedLines, const [
            'CILINDRAJE',
            'CILINDRADA',
          ], _isTrustedEngine),
        ) ??
        _cylinderValue(normalizedLines);
    final fuelType = _nearestValue(normalizedLines, const [
      'COMBUSTIBLE',
    ], _isTrustedFuel);

    final values = [
      fallback.plate,
      vin,
      fallback.brand,
      model,
      year,
      engine,
      fuelType,
    ];
    return PropertyCardOcrDraft(
      plate: fallback.plate,
      vin: vin,
      brand: fallback.brand,
      model: model,
      year: year,
      engine: engine,
      fuelType: fuelType,
      detectedFields: values
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .length,
    );
  }

  static String _normalize(String value) => value
      .trim()
      .replaceAll(RegExp(r'[^A-Z0-9ÁÉÍÓÚÜÑ .:/-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static String? _findBrand(String text, List<String> activeBrands) {
    final brands =
        activeBrands.map(_normalize).where((brand) => brand.isNotEmpty).toList()
          ..sort((left, right) => right.length.compareTo(left.length));
    for (final brand in brands) {
      if (RegExp(
        '(?<![A-Z0-9])${RegExp.escape(brand)}(?![A-Z0-9])',
      ).hasMatch(text)) {
        return brand;
      }
    }
    return null;
  }

  static String? _vinNearLabel(List<String> lines) {
    final candidate = _valueNearLabel(lines, const ['VIN', 'NIV', 'CHASIS']);
    return candidate == null
        ? null
        : _vinPattern.firstMatch(candidate)?.group(0);
  }

  static String? _modelNearLabel(List<String> lines) {
    final candidate = _valueNearLabel(lines, const ['LINEA']);
    if (candidate == null || _isDocumentNoise(candidate)) return null;
    if (candidate.length > 28 || _yearPattern.hasMatch(candidate)) return null;
    return candidate;
  }

  static String? _yearNearLabel(List<String> lines) {
    final candidate = _valueNearLabel(lines, const ['MODELO', 'ANO', 'AÑO']);
    return candidate == null
        ? null
        : _yearPattern.firstMatch(candidate)?.group(0);
  }

  static String? _engineNearLabel(List<String> lines) {
    const labels = ['CILINDRAJE', 'CILINDRADA'];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!labels.any((label) => line.contains(label))) continue;
      // Some Colombian licences print "CILINDRADA CC" on one line and the
      // number immediately below it. Check both without ever consulting the
      // unrelated motor or serial-number fields.
      for (
        var offset = 0;
        offset <= 2 && index + offset < lines.length;
        offset++
      ) {
        final candidate = offset == 0
            ? line.replaceAll(RegExp(r'CILINDRA(?:JE|DA)\s*(CC)?'), '').trim()
            : lines[index + offset];
        if (_isTrustedEngine(candidate)) return _formatEngine(candidate);
      }
    }
    return null;
  }

  static String? _valueNearLabel(List<String> lines, List<String> labels) {
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      for (final label in labels) {
        final match = RegExp(
          '(?:^|\\s)${RegExp.escape(label)}(?=\\s|\$)',
        ).firstMatch(line);
        if (match == null) continue;

        final inline = line
            .substring(match.end)
            .replaceFirst(RegExp(r'^[ .:/-]+'), '')
            .trim();
        final candidate = inline.isNotEmpty
            ? inline
            : index + 1 < lines.length
            ? lines[index + 1]
            : '';
        final normalized = _cleanLabelValue(candidate);
        if (normalized.isNotEmpty) return normalized;
      }
    }
    return null;
  }

  static bool _isDocumentNoise(String value) {
    const noise = [
      'REPUBLICA',
      'COLOMBIA',
      'LICENCIA',
      'TRANSITO',
      'TRÁNSITO',
      'ORDEN',
      'AUTORIDAD',
    ];
    return noise.any(value.contains);
  }

  static String? _nearestValue(
    List<_PositionedLine> lines,
    List<String> labels,
    bool Function(String value) accepts,
  ) {
    _PositionedLine? label;
    for (final candidate in lines) {
      if (_labelMatch(candidate.value, labels) != null) {
        label = candidate;
        break;
      }
    }
    if (label == null) return null;

    final labelMatch = _labelMatch(label.value, labels)!;
    final afterLabel = label.value.substring(labelMatch.end).trim();
    if (accepts(afterLabel)) return afterLabel;
    final beforeLabel = label.value.substring(0, labelMatch.start).trim();
    if (accepts(beforeLabel)) return beforeLabel;

    _PositionedLine? nearest;
    var nearestDistance = double.infinity;
    for (final candidate in lines) {
      if (candidate == label ||
          _isLabel(candidate.value) ||
          !accepts(candidate.value)) {
        continue;
      }
      final horizontal = (candidate.source.centerX - label.source.centerX)
          .abs();
      final vertical = candidate.source.centerY - label.source.centerY;
      // Colombian licences are arranged as headers with their values below.
      // Prefer the same column; retain a penalized lateral fallback for an
      // alternate document layout.
      final sameColumn =
          horizontal <= (label.source.right - label.source.left) * 1.8 + 24;
      final distance = vertical > 0 && sameColumn
          ? vertical * vertical + horizontal * horizontal * 0.2
          : (horizontal * horizontal + vertical * vertical) * 4;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = candidate;
      }
    }
    return nearest?.value;
  }

  static RegExpMatch? _labelMatch(String value, List<String> labels) {
    for (final label in labels) {
      final match = RegExp(
        '(?:^|\\s)${RegExp.escape(label)}(?=\\s|\$)',
      ).firstMatch(value);
      if (match != null) return match;
    }
    return null;
  }

  static bool _isLabel(String value) => const [
    'PLACA',
    'MARCA',
    'LINEA',
    'LÍNEA',
    'MODELO',
    'ANO',
    'AÑO',
    'CILINDRAJE',
    'CILINDRADA',
    'COMBUSTIBLE',
    'MOTOR',
    'CHASIS',
    'VIN',
    'NIV',
  ].contains(value);

  static bool _isTrustedModel(String value) =>
      value.length >= 2 &&
      value.length <= 24 &&
      RegExp(r'^[A-Z0-9 .-]+$').hasMatch(value) &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      !_isDocumentNoise(value) &&
      !_platePattern.hasMatch(value) &&
      !_vinPattern.hasMatch(value) &&
      !_yearPattern.hasMatch(value);

  static bool _isTrustedEngine(String value) =>
      RegExp(r'^[0-9]{1,4}(?:[.,][0-9]{1,3})?(?:\s*CC)?$').hasMatch(value);

  static String? _formatEngine(String? value) {
    if (value == null || !_isTrustedEngine(value)) return null;
    return value.endsWith('CC') ? value : '$value CC';
  }

  static bool _isTrustedFuel(String value) => const [
    'GASOLINA',
    'DIESEL',
    'DIÉSEL',
    'GAS',
    'ELECTRICO',
    'ELÉCTRICO',
    'HIBRIDO',
    'HÍBRIDO',
  ].contains(value);

  static String? _modelForBrand(List<_PositionedLine> lines, String? brand) {
    if (brand == null || brand.isEmpty) return null;
    final compactBrand = brand.replaceAll(' ', '');
    for (final line in lines) {
      final value = line.value;
      if (_isLabel(value) || !_isTrustedModel(value)) continue;
      final compactValue = value.replaceAll(' ', '');
      if (compactValue.startsWith(compactBrand) &&
          RegExp(r'[0-9]{2,4}').hasMatch(compactValue)) {
        return value;
      }
    }
    return null;
  }

  static String? _cylinderValue(List<_PositionedLine> lines) {
    final pattern = RegExp(
      r'(?<![0-9])[0-9]{3,4}(?:[.,][0-9]{1,3})?\s*CC(?![A-Z0-9])',
    );
    for (final line in lines) {
      final match = pattern.firstMatch(line.value);
      if (match != null) return _formatEngine(match.group(0));
    }
    return null;
  }

  static String _cleanLabelValue(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'^(DE |DEL |VEHICULO |VEHÍCULO )'), '')
        .trim();
    if (cleaned.length < 2 || cleaned.length > 40) return '';
    return cleaned;
  }
}

class _PositionedLine {
  const _PositionedLine(this.source, this.value);

  final PropertyCardOcrLine source;
  final String value;
}
