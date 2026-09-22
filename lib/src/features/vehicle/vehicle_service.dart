import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_models.dart';
import 'vehicle_models.dart';

class VehicleService {
  VehicleService({required this.apiBaseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String apiBaseUrl;
  final http.Client _client;

  Future<List<Vehicle>> list(AuthSession session) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$apiBaseUrl/api/v1/vehicles'),
            headers: _headers(session),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decode(response.body);
      if (response.statusCode != 200) {
        throw VehicleException(_messageFor(body, response.statusCode));
      }
      final items = body['items'];
      if (items is! List) return const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(Vehicle.fromJson)
          .toList();
    } on TimeoutException {
      throw const VehicleException(
        'El servidor tardó demasiado. Inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } catch (_) {
      throw const VehicleException(
        'No fue posible consultar tus vehículos. Verifica la conexión con el servidor.',
      );
    }
  }

  Future<Vehicle> create({
    required AuthSession session,
    String? nickname,
    required String plate,
    String? vin,
    required String brand,
    required String model,
    required int year,
    String? engine,
    String? fuelType,
    String? transmission,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$apiBaseUrl/api/v1/vehicles'),
            headers: _headers(session),
            body: jsonEncode({
              'nickname': nickname,
              'plate': plate,
              'vin': vin,
              'brand': brand,
              'model': model,
              'year': year,
              'engine': engine,
              'fuelType': fuelType,
              'transmission': transmission,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decode(response.body);
      if (response.statusCode != 201) {
        throw VehicleException(_messageFor(body, response.statusCode));
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        'El servidor tardó demasiado. Inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } catch (_) {
      throw const VehicleException(
        'No fue posible guardar el vehículo. Verifica la conexión con el servidor.',
      );
    }
  }

  Future<Vehicle> updateProfile({
    required AuthSession session,
    required String vehicleId,
    String? nickname,
    required String brand,
    required String model,
    String? engine,
    String? fuelType,
    String? transmission,
  }) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('$apiBaseUrl/api/v1/vehicles/$vehicleId'),
            headers: _headers(session),
            body: jsonEncode({
              'nickname': nickname,
              'brand': brand,
              'model': model,
              'engine': engine,
              'fuelType': fuelType,
              'transmission': transmission,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decode(response.body);
      if (response.statusCode != 200) {
        throw VehicleException(_messageFor(body, response.statusCode));
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        'El servidor tardó demasiado. Inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } catch (_) {
      throw const VehicleException(
        'No fue posible actualizar el vehículo. Verifica la conexión con el servidor.',
      );
    }
  }

  Future<Vehicle> get({
    required AuthSession session,
    required String vehicleId,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$apiBaseUrl/api/v1/vehicles/$vehicleId'),
            headers: _headers(session),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decode(response.body);
      if (response.statusCode != 200) {
        throw VehicleException(_messageFor(body, response.statusCode));
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        'El servidor tardó demasiado. Inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } catch (_) {
      throw const VehicleException(
        'No fue posible consultar el vehículo. Verifica la conexión con el servidor.',
      );
    }
  }

  Future<Vehicle> updateVin({
    required AuthSession session,
    required String vehicleId,
    String? vin,
  }) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('$apiBaseUrl/api/v1/vehicles/$vehicleId/vin'),
            headers: _headers(session),
            body: jsonEncode({'vin': vin}),
          )
          .timeout(const Duration(seconds: 12));
      final body = _decode(response.body);
      if (response.statusCode != 200) {
        throw VehicleException(_messageFor(body, response.statusCode));
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        'El servidor tardó demasiado. Inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } catch (_) {
      throw const VehicleException(
        'No fue posible actualizar el VIN. Verifica la conexión con el servidor.',
      );
    }
  }

  Map<String, String> _headers(AuthSession session) => {
    'Content-Type': 'application/json',
    'Authorization': '${session.tokenType} ${session.accessToken}',
  };

  Map<String, dynamic> _decode(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _messageFor(Map<String, dynamic> body, int statusCode) {
    final code = body['code']?.toString();
    if (code == 'VEHICLE_ALREADY_EXISTS') {
      return 'Ya tienes un vehículo registrado con esa placa.';
    }
    if (code == 'VALIDATION_ERROR') {
      return body['message']?.toString() ?? 'Revisa los datos del vehículo.';
    }
    if (code == 'VEHICLE_NOT_FOUND' || statusCode == 404) {
      return 'No encontramos este vehículo en tu cuenta.';
    }
    if (statusCode == 401) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    return 'No fue posible guardar el vehículo. Inténtalo de nuevo.';
  }
}

class VehicleException implements Exception {
  const VehicleException(this.message);

  final String message;

  @override
  String toString() => message;
}
