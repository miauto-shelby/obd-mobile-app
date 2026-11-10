import 'package:flutter_test/flutter_test.dart';
import 'package:obd_mobile_app/src/features/vehicle/property_card_ocr.dart';

void main() {
  group('PropertyCardOcrParser', () {
    test('proposes values only from valid vehicle-document patterns', () {
      const text = '''
        REPUBLICA DE COLOMBIA
        PLACA ABC123
        MARCA CHEVROLET
        LINEA ONIX TURBO
        MODELO 2022
        VIN 1HGCM82633A004352
        CILINDRAJE 1000
      ''';

      final draft = PropertyCardOcrParser.parse(
        text,
        activeBrands: const ['CHEVROLET', 'MAZDA'],
      );

      expect(draft.plate, 'ABC123');
      expect(draft.vin, '1HGCM82633A004352');
      expect(draft.brand, 'CHEVROLET');
      expect(draft.model, 'ONIX TURBO');
      expect(draft.year, '2022');
      expect(draft.engine, '1000 CC');
      expect(draft.hasUsefulData, isTrue);
    });

    test('does not propose an invalid VIN or an unknown brand', () {
      const text = 'PLACA ABC12D VIN 1M8GDM9AXKP04278I MARCA DESCONOCIDA';

      final draft = PropertyCardOcrParser.parse(
        text,
        activeBrands: const ['CHEVROLET', 'MAZDA'],
      );

      expect(draft.plate, 'ABC12D');
      expect(draft.vin, isNull);
      expect(draft.brand, isNull);
    });

    test('leaves ambiguous document text empty instead of misplacing it', () {
      const text = '''
        PLACA NDR423
        LINEA LIBERTADY ORDEN LICENCIA DE TRANSITO
        MODELO LIBERTADY ORDEN LICENCIA DE TRANSITO
        MOTOR LSJA16E34DG00084
      ''';

      final draft = PropertyCardOcrParser.parse(
        text,
        activeBrands: const ['CHEVROLET', 'MAZDA'],
      );

      expect(draft.plate, 'NDR423');
      expect(draft.model, isNull);
      expect(draft.year, isNull);
      expect(draft.engine, isNull);
    });

    test('maps Colombian licence fields by their nearby labels', () {
      const lines = [
        PropertyCardOcrLine(
          text: 'PLACA',
          left: 0,
          top: 0,
          right: 40,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: 'NDR423',
          left: 0,
          top: 20,
          right: 50,
          bottom: 30,
        ),
        PropertyCardOcrLine(
          text: 'MARCA',
          left: 80,
          top: 0,
          right: 125,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: 'MG',
          left: 80,
          top: 20,
          right: 100,
          bottom: 30,
        ),
        PropertyCardOcrLine(
          text: 'LINEA',
          left: 160,
          top: 0,
          right: 205,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: 'MG 350',
          left: 160,
          top: 20,
          right: 215,
          bottom: 30,
        ),
        PropertyCardOcrLine(
          text: 'MODELO',
          left: 240,
          top: 0,
          right: 295,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: '2013',
          left: 240,
          top: 20,
          right: 280,
          bottom: 30,
        ),
        PropertyCardOcrLine(
          text: 'CILINDRAJE',
          left: 0,
          top: 80,
          right: 90,
          bottom: 90,
        ),
        PropertyCardOcrLine(
          text: '1498 CC',
          left: 0,
          top: 100,
          right: 65,
          bottom: 110,
        ),
        PropertyCardOcrLine(
          text: 'COMBUSTIBLE',
          left: 120,
          top: 80,
          right: 220,
          bottom: 90,
        ),
        PropertyCardOcrLine(
          text: 'GASOLINA',
          left: 120,
          top: 100,
          right: 195,
          bottom: 110,
        ),
      ];

      final draft = PropertyCardOcrParser.parseRecognized(
        rawText: lines.map((line) => line.text).join('\n'),
        lines: lines,
        activeBrands: const ['MG', 'MAZDA'],
      );

      expect(draft.plate, 'NDR423');
      expect(draft.brand, 'MG');
      expect(draft.model, 'MG 350');
      expect(draft.year, '2013');
      expect(draft.engine, '1498 CC');
      expect(draft.fuelType, 'GASOLINA');
    });

    test('accepts a value before its rotated OCR label', () {
      const lines = [
        PropertyCardOcrLine(
          text: 'MG 350 LINEA',
          left: 0,
          top: 0,
          right: 100,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: '1498 CC CILINDRAJE',
          left: 0,
          top: 30,
          right: 130,
          bottom: 40,
        ),
      ];

      final draft = PropertyCardOcrParser.parseRecognized(
        rawText: lines.map((line) => line.text).join('\n'),
        lines: lines,
        activeBrands: const [],
      );

      expect(draft.model, 'MG 350');
      expect(draft.engine, '1498 CC');
    });

    test('uses safe Colombian licence fallbacks for model and cilindraje', () {
      const lines = [
        PropertyCardOcrLine(
          text: 'MARCA MG',
          left: 0,
          top: 0,
          right: 70,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: 'MG 350',
          left: 80,
          top: 0,
          right: 135,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: '1498 CC',
          left: 0,
          top: 30,
          right: 65,
          bottom: 40,
        ),
      ];

      final draft = PropertyCardOcrParser.parseRecognized(
        rawText: lines.map((line) => line.text).join('\n'),
        lines: lines,
        activeBrands: const ['MG'],
      );

      expect(draft.model, 'MG 350');
      expect(draft.engine, '1498 CC');
    });

    test('recognizes CILINDRADA CC and VIN values in their own columns', () {
      const lines = [
        PropertyCardOcrLine(
          text: 'CILINDRADA CC',
          left: 0,
          top: 0,
          right: 105,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: '1.498',
          left: 0,
          top: 20,
          right: 45,
          bottom: 30,
        ),
        PropertyCardOcrLine(
          text: 'VIN',
          left: 150,
          top: 0,
          right: 180,
          bottom: 10,
        ),
        PropertyCardOcrLine(
          text: 'LSJA16E34DG000084',
          left: 150,
          top: 20,
          right: 280,
          bottom: 30,
        ),
      ];

      final draft = PropertyCardOcrParser.parseRecognized(
        rawText: lines.map((line) => line.text).join('\n'),
        lines: lines,
        activeBrands: const [],
      );

      expect(draft.engine, '1.498 CC');
      expect(draft.vin, 'LSJA16E34DG000084');
    });
  });
}
