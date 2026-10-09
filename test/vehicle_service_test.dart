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

  test('explains that a duplicate plate is already registered', () async {
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'code': 'VEHICLE_ALREADY_EXISTS'}), 409),
      ),
    );

    expectLater(
      service.create(
        session: _session,
        plate: 'ABC123',
        brand: 'Chevrolet',
        model: 'Onix',
        year: 2022,
      ),
      throwsA(
        isA<VehicleException>()
            .having(
              (error) => error.kind,
              'kind',
              VehicleErrorKind.duplicatePlate,
            )
            .having(
              (error) => error.message,
              'message',
              contains('ya está registrada'),
            ),
      ),
    );
  });

  test('explains that manual mileage is not accepted', () async {
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'VALIDATION_ERROR',
            'message':
                'El kilometraje solo puede llegar desde una lectura OBD2.',
          }),
          400,
        ),
      ),
    );

    expectLater(
      service.create(
        session: _session,
        plate: 'ABC123',
        brand: 'Chevrolet',
        model: 'Onix',
        year: 2022,
      ),
      throwsA(
        isA<VehicleException>()
            .having(
              (error) => error.kind,
              'kind',
              VehicleErrorKind.obdOnlyMileage,
            )
            .having((error) => error.message, 'message', contains('OBD2')),
      ),
    );
  });

  test('explains when the session is no longer valid', () async {
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'code': 'INVALID_ACCESS_TOKEN'}), 401),
      ),
    );

    expectLater(
      service.list(_session),
      throwsA(
        isA<VehicleException>()
            .having((error) => error.kind, 'kind', VehicleErrorKind.session)
            .having(
              (error) => error.message,
              'message',
              contains('sesión venció'),
            ),
      ),
    );
  });

  test('deactivates a vehicle without deleting its history', () async {
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/vehicles/vehicle-1');
        expect(request.headers['authorization'], 'Bearer access');
        return http.Response('', 204);
      }),
    );

    await service.deactivate(session: _session, vehicleId: 'vehicle-1');
  });

  test('explains when a vehicle has an active OBD2 reading', () async {
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'code': 'OBD_SESSION_ACTIVE'}), 409),
      ),
    );

    expectLater(
      service.deactivate(session: _session, vehicleId: 'vehicle-1'),
      throwsA(
        isA<VehicleException>()
            .having(
              (error) => error.kind,
              'kind',
              VehicleErrorKind.obdSessionActive,
            )
            .having((error) => error.message, 'message', contains('OBD2')),
      ),
    );
  });

  test('gets and changes the active vehicle', () async {
    var requestedSelection = false;
    final service = VehicleService(
      apiBaseUrl: 'http://api.test',
      client: MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/api/v1/vehicles/active');
          return http.Response(jsonEncode(_vehicleJson), 200);
        }
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/vehicles/active');
        expect(jsonDecode(request.body), {'vehicleId': 'vehicle-1'});
        requestedSelection = true;
        return http.Response(jsonEncode(_vehicleJson), 200);
      }),
    );

    expect((await service.getActive(_session))?.vehicleId, 'vehicle-1');
    expect(
      (await service.selectActive(
        session: _session,
        vehicleId: 'vehicle-1',
      )).vehicleId,
      'vehicle-1',
    );
    expect(requestedSelection, isTrue);
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
