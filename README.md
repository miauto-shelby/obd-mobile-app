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

## Ambientes y URL del backend

La app usa variables de compilación de Flutter (`--dart-define`); no lee URI de Atlas, contraseñas ni secretos desde el móvil. Usa `APP_ENV=development`, `test` o `production`.

En `development`, si no defines `API_BASE_URL`, la app usa `http://127.0.0.1:8080`. Para `test` y `production`, `API_BASE_URL` y `GOOGLE_SERVER_CLIENT_ID` son obligatorias.

No uses `localhost` en el celular o emulador. Para desarrollo USB con `adb reverse`, usa `127.0.0.1`:

```bash
flutter run --dart-define=APP_ENV=development
```

Para emulador Android:

```bash
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Para teléfono físico:

```bash
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://192.168.1.50:8080
```

Sustituye `192.168.1.50` por la IP real de tu PC en la red local.

## Variables por ambiente

El Client ID de Google identifica la aplicación, pero no es un secreto. Nunca incluyas `MONGODB_URI`, `MONGODB_PASSWORD` ni `JWT_SECRET` en estos comandos o en el repositorio: pertenecen únicamente al backend.

```bash
flutter run ^
  --dart-define=APP_ENV=development ^
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 ^
  --dart-define=GOOGLE_CLIENT_ID=tu-client-id ^
  --dart-define=GOOGLE_SERVER_CLIENT_ID=tu-server-client-id
```

Ejemplo de compilación para producción, cuando exista una URL HTTPS de backend aprobada:

```bash
flutter build appbundle ^
  --dart-define=APP_ENV=production ^
  --dart-define=API_BASE_URL=https://api.ejemplo.com ^
  --dart-define=GOOGLE_SERVER_CLIENT_ID=tu-client-id-web
```
