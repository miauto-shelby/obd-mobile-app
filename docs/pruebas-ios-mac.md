# Pruebas locales de My Auto en iPhone

Esta guía permite que una arquitecta ejecute My Auto en un iPhone físico sin instalar Node.js ni MongoDB en su Mac. Docker Desktop inicia el backend y una base de datos local. Xcode compila y firma la app.

## Qué necesita

- Una Mac con una versión compatible de macOS y Xcode.
- Docker Desktop, Git y Flutter instalados.
- Una cuenta de Apple iniciada en Xcode. Para instalar en un iPhone físico, el equipo de Apple Developer debe tener permiso para usar el Bundle ID de My Auto.
- Un iPhone, cable USB y conexión a la misma red Wi-Fi que la Mac.
- Acceso de lectura a los repositorios `obd-platform` y `obd-mobile-app`.

No necesita instalar MongoDB, Node.js, Atlas ni copiar archivos `.env` de otra persona.

## Preparación única de iOS

Esta configuración se hace una vez en la rama de la aplicación, no cada vez que alguien prueba la app:

1. Definir el Bundle ID final de My Auto. El valor actual de ejemplo no se debe conservar para distribución.
2. En Google Cloud, confirmar que el cliente OAuth de iOS usa exactamente ese Bundle ID.
3. Configurar en `ios/Runner/Info.plist` el Client ID de iOS, el Client ID web del backend y el esquema URL de iOS asociado al Client ID.
4. En Xcode, seleccionar el equipo de Apple que puede firmar ese Bundle ID.

Los Client ID identifican la aplicación, pero nunca se deben incluir secretos de clientes, URI de Atlas, contraseñas o `JWT_SECRET` en la app.

No continúes con el inicio de sesión de Google si esta preparación no está incorporada todavía en la rama. La app puede compilar, pero Google no podrá volver correctamente al iPhone después de elegir una cuenta.

## 1. Descargar los proyectos

En Terminal, crear una carpeta de trabajo y clonar los dos repositorios aprobados:

```bash
mkdir -p ~/Developer/my-auto
cd ~/Developer/my-auto
git clone https://github.com/miauto-shelby/obd-platform.git
git clone https://github.com/miauto-shelby/obd-mobile-app.git
```

Usar las ramas indicadas por la revisión de arquitectura. No trabajar directamente en `main` mientras una Pull Request esté pendiente de aprobación.

## 2. Preparar Docker local

Abrir Docker Desktop y esperar a que indique que está listo. Después, desde el repositorio `obd-platform`:

```bash
cd ~/Developer/my-auto/obd-platform
cp .env.docker.example .env.docker
```

Editar solamente el valor local de `JWT_SECRET` en `.env.docker`. Ese archivo no se sube a Git y no debe contener credenciales de Atlas.

Para que el iPhone pueda alcanzar el backend de Docker desde la misma red Wi-Fi, iniciar los servicios así:

```bash
API_HOST_BINDING=0.0.0.0 docker compose --env-file .env.docker -f compose.local.yaml up --build --detach
```

Comprobar que Docker respondió dentro de la Mac:

```bash
curl http://127.0.0.1:8081/health
```

La respuesta esperada es:

```json
{"status":"ok"}
```

## 3. Obtener y comprobar la IP de la Mac

Con la Mac y el iPhone conectados a la misma Wi-Fi, obtener la IP local de la Mac:

```bash
ipconfig getifaddr en0
```

Si no muestra un valor, consultar la dirección IP en **Configuración del Sistema > Wi-Fi > Detalles**. Ejemplo: `192.168.1.25`.

En Safari del iPhone, abrir:

```text
http://192.168.1.25:8081/health
```

Sustituir la IP por la real. Debe verse `{"status":"ok"}`. Si no responde, confirmar que ambos dispositivos están en la misma red y permitir conexiones entrantes para Docker en el firewall de macOS.

## 4. Preparar Xcode y el iPhone

1. Conectar el iPhone por USB, desbloquearlo y elegir **Confiar** cuando lo solicite.
2. Abrir Xcode e iniciar sesión con la cuenta de Apple de la arquitecta.
3. Desde el proyecto móvil, ejecutar:

```bash
cd ~/Developer/my-auto/obd-mobile-app
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

4. En Xcode, seleccionar el proyecto **Runner**, luego el target **Runner** y la pestaña **Signing & Capabilities**.
5. Elegir el Team autorizado. No cambiar el Bundle ID sin avisar: debe coincidir con Apple Developer y Google Cloud.
6. Elegir el iPhone conectado como destino y presionar Run una primera vez. Aceptar en el teléfono cualquier permiso de desarrollador que solicite iOS.

## 5. Ejecutar Flutter contra Docker

Cerrar la ejecución anterior de Xcode si quedó abierta. En Terminal, desde `obd-mobile-app`, ejecutar:

```bash
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://IP_DE_LA_MAC:8081
```

Reemplazar `IP_DE_LA_MAC` por la IP confirmada en el paso 3. Para el simulador de iPhone en la misma Mac, se puede usar `http://127.0.0.1:8081` en lugar de la IP local.

La app debe abrirse en el iPhone. Probar inicio de sesión, creación de vehículo, edición, VIN, cambio de vehículo activo y eliminación lógica. No usar datos reales sensibles durante pruebas locales.

## Diagnóstico rápido

| Síntoma | Verificación |
| --- | --- |
| Docker no inicia | Ejecutar `docker compose -f compose.local.yaml logs api` desde `obd-platform`. |
| El iPhone no llega al backend | Abrir `/health` en Safari del iPhone y revisar Wi-Fi, IP y firewall. |
| Xcode no detecta el iPhone | Desbloquearlo, confiar en la Mac y revisar **Devices and Simulators** en Xcode. |
| Error de firma | Revisar el Team y el Bundle ID en Xcode. |
| Google abre pero no regresa a My Auto | Revisar Client ID iOS y URL scheme en `ios/Runner/Info.plist`. |
| La app dice que falta el Client ID web | Ejecutar Flutter con `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` o revisar la configuración aprobada de desarrollo. |

## Al terminar

Detener los contenedores, conservando los datos de prueba locales:

```bash
cd ~/Developer/my-auto/obd-platform
API_HOST_BINDING=0.0.0.0 docker compose -f compose.local.yaml down
```

Para borrar solo los datos locales de prueba cuando ya no se necesiten:

```bash
API_HOST_BINDING=0.0.0.0 docker compose -f compose.local.yaml down --volumes
```

Este último comando no toca Atlas ni los datos de desarrollo remotos, pero sí elimina la base local de Docker.
