# My Auto

Frontend Flutter para la app móvil `My Auto`.

## Backend

Este frontend consume el backend que vive en `OBD2-API`.

## Login

El front hace `POST /api/v1/auth/google` al backend.

Body esperado:

```json
{
  "idToken": "google-id-token",
  "deviceId": "device-123",
  "deviceName": "Pixel 8",
  "platform": "ANDROID",
  "appVersion": "1.0.0"
}
```

## URL del backend

No uses `localhost` en el celular o emulador.

Para emulador Android:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para teléfono físico:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
```

Sustituye `192.168.1.50` por la IP real de tu PC en la red local.

## Variables opcionales

```bash
flutter run ^
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 ^
  --dart-define=GOOGLE_CLIENT_ID=tu-client-id ^
  --dart-define=GOOGLE_SERVER_CLIENT_ID=tu-server-client-id
```
