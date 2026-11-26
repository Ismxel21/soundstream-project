# API de SoundStream (backend)

Backend en Java 17 sobre Tomcat 10.1 (Jakarta Servlet 6), autenticación por sesión y acceso a PostgreSQL por JDBC.
Responsable: Integrante 1. Consumidor principal: Integrante 2 (frontend).

## Convenciones

- **Origen único:** el navegador llama con rutas relativas (`/api/...`). Todo pasa por Cloudflare Tunnel y Nginx, así que no se necesita CORS.
- **Prefijo:** todos los endpoints viven bajo `/api/`, y Nginx reenvía `/api/` a Tomcat con una sola regla.
- **Formato:** `application/json` en peticiones y respuestas, salvo `/api/audio/{id}` (ver sección 4).
- **Sesión:** la cookie de sesión la crea Tomcat en el login (`HttpOnly`; `Secure` cuando se sirve por HTTPS). El navegador la envía solo, incluso en el reproductor `<audio>`.
- **Errores:** siempre JSON con el campo `error`, por ejemplo `{"error": "Invalid credentials"}`.

## 1. Estado del servicio

`GET /api/health` — público

Respuesta `200 OK`:

```json
{ "status": "UP", "service": "soundstream-api", "database": "UP" }
```

Respuesta `503 Service Unavailable` cuando PostgreSQL no responde (la usa la prueba de monitoreo):

```json
{ "status": "DOWN", "service": "soundstream-api", "database": "DOWN", "error": "Database connection unavailable" }
```

## 2. Iniciar sesión

`POST /api/login` — público

Cuerpo:

```json
{ "username": "usuario_demo", "password": "********" }
```

| Código | Cuándo | Cuerpo |
|---|---|---|
| 200 | Credenciales válidas; crea la sesión | `{"authenticated": true, "user": {"id": 1, "username": "usuario_demo"}}` |
| 400 | JSON inválido o campos vacíos | `{"error": "Invalid request"}` |
| 401 | Credenciales incorrectas | `{"authenticated": false, "error": "Invalid credentials"}` |

## 3. Cerrar sesión (propuesto)

`POST /api/logout` — requiere sesión. Responde `204 No Content` e invalida la sesión.

## 4. Audio

`GET /api/audio/{id}` — requiere sesión

- `id`: entero, identificador de la canción en la base de datos.
- Tomcat solo **autoriza**: no envía el archivo. Si todo es válido responde `200` sin cuerpo y con la cabecera `X-Accel-Redirect` hacia una ruta interna de Nginx, y Nginx entrega el audio con soporte HTTP Range (`206 Partial Content`).
- Para el frontend: basta `<audio src="/api/audio/12">`. El navegador gestiona los saltos de posición con Range.

| Código | Cuándo |
|---|---|
| 200 | Autorizado (cuerpo vacío + `X-Accel-Redirect`; el cliente recibe el audio) |
| 400 | `id` no numérico |
| 401 | Sin sesión válida |
| 403 | Sesión válida pero sin permiso sobre la pista |
| 404 | La pista no existe |

## 5. Pendiente por definir

- Catálogo de canciones, búsqueda y playlists: endpoints a acordar con el Integrante 2 (se agregan aquí al cerrarlos).
- Ruta interna de `X-Accel-Redirect` (`internal;` en Nginx): a confirmar con el Integrante 3. No la ve el cliente.
