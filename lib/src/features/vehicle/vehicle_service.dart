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
        throw _exceptionFor(
          body,
          response.statusCode,
          fallback:
              'No fue posible consultar tus vehículos. Inténtalo de nuevo.',
        );
      }
      final items = body['items'];
      if (items is! List) return const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(Vehicle.fromJson)
          .toList();
    } on TimeoutException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'El servidor tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } on http.ClientException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'No fue posible conectarse con el servidor. Revisa tu red e inténtalo de nuevo.',
      );
    } catch (_) {
      throw const VehicleException(
        VehicleErrorKind.network,
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
        throw _exceptionFor(
          body,
          response.statusCode,
          fallback: 'No fue posible guardar el vehículo. Inténtalo de nuevo.',
        );
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'El servidor tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } on http.ClientException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'No fue posible conectarse con el servidor. Revisa tu red e inténtalo de nuevo.',
      );
    } catch (_) {
      throw const VehicleException(
        VehicleErrorKind.network,
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
        throw _exceptionFor(
          body,
          response.statusCode,
          fallback:
              'No fue posible actualizar el vehículo. Inténtalo de nuevo.',
        );
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'El servidor tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } on http.ClientException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'No fue posible conectarse con el servidor. Revisa tu red e inténtalo de nuevo.',
      );
    } catch (_) {
      throw const VehicleException(
        VehicleErrorKind.network,
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
        throw _exceptionFor(
          body,
          response.statusCode,
          fallback: 'No fue posible consultar el vehículo. Inténtalo de nuevo.',
        );
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'El servidor tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } on http.ClientException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'No fue posible conectarse con el servidor. Revisa tu red e inténtalo de nuevo.',
      );
    } catch (_) {
      throw const VehicleException(
        VehicleErrorKind.network,
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
        throw _exceptionFor(
          body,
          response.statusCode,
          fallback: 'No fue posible actualizar el VIN. Inténtalo de nuevo.',
        );
      }
      return Vehicle.fromJson(body);
    } on TimeoutException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'El servidor tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on VehicleException {
      rethrow;
    } on http.ClientException {
      throw const VehicleException(
        VehicleErrorKind.network,
        'No fue posible conectarse con el servidor. Revisa tu red e inténtalo de nuevo.',
      );
    } catch (_) {
      throw const VehicleException(
        VehicleErrorKind.network,
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

  VehicleException _exceptionFor(
    Map<String, dynamic> body,
    int statusCode, {
    required String fallback,
  }) {
    final code = body['code']?.toString();
    if (code == 'VEHICLE_ALREADY_EXISTS') {
      return const VehicleException(
        VehicleErrorKind.duplicatePlate,
        'Esta placa ya está registrada. Revisa los datos o usa otra placa.',
      );
    }
    if (code == 'VALIDATION_ERROR') {
      return _validationException(body['message']?.toString());
    }
    if (code == 'VEHICLE_NOT_FOUND' || statusCode == 404) {
      return const VehicleException(
        VehicleErrorKind.notFound,
        'No encontramos este vehículo en tu cuenta. Actualiza la lista e inténtalo de nuevo.',
      );
    }
    if (code == 'INVALID_ACCESS_TOKEN' || statusCode == 401) {
      return const VehicleException(
        VehicleErrorKind.session,
        'Tu sesión venció. Vuelve a iniciar sesión para continuar.',
      );
    }
    if (code == 'ADMIN_ACCESS_REQUIRED' || statusCode == 403) {
      return const VehicleException(
        VehicleErrorKind.permission,
        'No tienes permiso para realizar esta acción.',
      );
    }
    return VehicleException(VehicleErrorKind.server, fallback);
  }

  VehicleException _validationException(String? backendMessage) {
    final message = (backendMessage ?? '').toLowerCase();
    if (message.contains('vin')) {
      return const VehicleException(
        VehicleErrorKind.invalidVin,
        'El VIN debe tener 17 caracteres válidos. Revisa el dato e inténtalo de nuevo.',
      );
    }
    if (message.contains('kilometraje')) {
      return const VehicleException(
        VehicleErrorKind.obdOnlyMileage,
        'El kilometraje se actualizará cuando conectes el adaptador OBD2; no se ingresa manualmente.',
      );
    }
    if (message.contains('placa')) {
      return const VehicleException(
        VehicleErrorKind.invalidPlate,
        'Revisa la placa. Usa letras, números, espacios o guiones.',
      );
    }
    if (message.contains('año')) {
      return const VehicleException(
        VehicleErrorKind.invalidVehicleData,
        'Revisa el año del vehículo e inténtalo de nuevo.',
      );
    }
    return const VehicleException(
      VehicleErrorKind.invalidVehicleData,
      'Revisa los datos del vehículo e inténtalo de nuevo.',
    );
  }
}

enum VehicleErrorKind {
  duplicatePlate,
  invalidPlate,
  invalidVin,
  obdOnlyMileage,
  invalidVehicleData,
  notFound,
  session,
  permission,
  network,
  server,
}

class VehicleException implements Exception {
  const VehicleException(this.kind, this.message);

  final VehicleErrorKind kind;
  final String message;

  @override
  String toString() => message;
}
