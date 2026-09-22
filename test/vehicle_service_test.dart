import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obd_mobile_app/src/features/auth/auth_models.dart';
import 'package:obd_mobile_app/src/features/vehicle/vehicle_service.dart';

void main() {
  test('creates a vehicle without sending manual mileage', () async {
    late Map<String, dynamic> requestBody;
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/vehicles');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(_vehicleJson), 201);
      }),
    );

    final vehicle = await service.create(
      session: _session,
      plate: 'ABC123',
      brand: 'Chevrolet',
      model: 'Onix',
      year: 2022,
    );

    expect(requestBody.containsKey('currentMileage'), isFalse);
    expect(vehicle.currentMileage, isNull);
    expect(vehicle.plate, 'ABC123');
  });

  test('updates allowed vehicle profile information', () async {
    late Map<String, dynamic> requestBody;
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/vehicles/vehicle-1');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(_vehicleJson), 200);
      }),
    );

    await service.updateProfile(
      session: _session,
      vehicleId: 'vehicle-1',
      nickname: 'Auto familiar',
      brand: 'Chevrolet',
      model: 'Onix',
      engine: null,
      fuelType: 'GASOLINE',
      transmission: null,
    );

    expect(requestBody['nickname'], 'Auto familiar');
    expect(requestBody.containsKey('currentMileage'), isFalse);
  });
}

const _session = AuthSession(
  request: GoogleAuthRequest(
    idToken: '',
    deviceId: 'test-device',
    deviceName: 'Test device',
    platform: 'ANDROID',
    appVersion: '1.0.0',
  ),
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresIn: 900,
  tokenType: 'Bearer',
  user: AuthUser(
    id: 'user-1',
    firstName: 'Sebastián',
    lastName: 'Fajardo',
    email: 'sebastian@example.com',
    photoUrl: '',
  ),
);

const _vehicleJson = {
  'vehicleId': 'vehicle-1',
  'nickname': null,
  'plate': 'ABC123',
  'vin': null,
  'brand': 'Chevrolet',
  'model': 'Onix',
  'year': 2022,
  'engine': null,
  'fuelType': null,
  'transmission': null,
  'currentMileage': null,
};
