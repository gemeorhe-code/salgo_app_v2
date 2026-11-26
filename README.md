# SALGO APP

Aplicación Flutter de recomendaciones de planes y lugares en Bucaramanga. El catálogo funciona con datos locales (`MockData`) cuando no hay conexión y se sincroniza con Supabase cuando el proyecto está configurado.

## Requisitos

- Flutter SDK 3.13.3 o superior (Dart incluido).
- Android Studio o VS Code con el plugin de Flutter.
- SDK de Android y un dispositivo/emulador con Android.
- Proyecto de Supabase para autenticación y sincronización.
- Proyecto de Google Cloud para Google Maps y Google Sign-In.

## Ejecución

1. Instala dependencias:

   ```bash
   flutter pub get
   ```

2. Configura Supabase y Google según las secciones siguientes.
3. Ejecuta la app:

   ```bash
   flutter run
   ```

4. Verifica el proyecto:

   ```bash
   flutter analyze
   flutter test
   ```

## Supabase

1. Crea un proyecto en Supabase.
2. Abre el SQL Editor y ejecuta `supabase/schema.sql`. El script crea seis tablas (`salgo_places`, `salgo_profiles`, `salgo_favorites`, `salgo_user_preferences`, `salgo_notification_states` y `salgo_user_roles`) con Row Level Security.
3. En Authentication > Providers habilita `Email` y `Google`.
4. Configura las URLs de redirección permitidas, incluida `salgo://auth`.
5. Actualiza `lib/data/supabase_config.dart` con la URL y la publishable key de tu proyecto.

La app usa el usuario autenticado (`auth.uid()`) para aislar perfil, favoritos, preferencias y estados de notificación. El catálogo `salgo_places` se lee en la app solo cuando `is_active = true`. Si Supabase no está disponible, la app continúa con el catálogo local.

### Roles y administración de lugares

Los roles viven en `salgo_user_roles` y no dependen de `perfiles.rol`.

- `admin`: puede crear, editar, activar o desactivar cualquier lugar y asignar dueños por correo exacto.
- `owner`: puede editar solo los lugares asignados; no crea lugares ni cambia `is_active`.
- Otros usuarios: solo leen lugares activos.

Los lugares `1..6` ya usados por favoritos y notificaciones se conservan y empiezan sin dueño. Los lugares nuevos nacen desde el id `1000`.

El primer administrador se asigna manualmente desde el SQL Editor, nunca desde la app. La cuenta debe haber iniciado sesión al menos una vez:

```sql
insert into public.salgo_user_roles (user_id, role)
select id, 'admin'
from auth.users
where lower(email) = lower('TU_CORREO@EJEMPLO.COM')
on conflict do nothing;
```

Para asignar un dueño, usa la pantalla “Administrar lugares” o ejecuta:

```sql
select public.salgo_assign_owner('correo@ejemplo.com', 1000);
```

También existe `public.salgo_remove_owner('correo@ejemplo.com', 1000)` para quitar la asignación.

Estas reglas protegen lo que hace la app con la anon key. No protegen lo que haga una persona directamente en el panel de Supabase con el rol `postgres` o con la service role key: desde ahí se pueden modificar los datos sin pasar por las políticas ni los triggers de la app.

### Prueba con dos cuentas

1. Crea la cuenta A (administrador) y la cuenta B (dueño) con Email en Supabase Auth e inicia sesión con ambas al menos una vez.
2. Asigna manualmente a A como `admin` con el SQL anterior.
3. Con A, entra a Perfil > “Administrar lugares”; crea un lugar nuevo, edítalo, cambia `is_active` y asigna a B como dueño por correo exacto.
4. Con B, entra a Perfil > “Administrar lugares”; confirma que solo ve y puede editar el lugar asignado y que no ve controles para crear ni para activar/desactivar.
5. Con una tercera cuenta sin rol, confirma que “Administrar lugares” no aparece.
6. Sin red, intenta guardar: la app debe mostrar “Sin conexión: no se puede guardar el lugar. Inténtalo cuando haya red.” y no debe encolar escrituras.
7. Si `salgo_my_place_access` falta o falla, la opción se oculta sin mensajes de error ni cierre de sesión.

### Claves públicas y secretas

Pueden estar en el repositorio:

- URL de Supabase.
- Publishable/anon key de Supabase.
- Web client ID de Google.
- El paquete Android `com.example.salgo_app`.

No deben estar en el repositorio:

- Service role key ni secret keys de Supabase.
- `client_secret.json`, `.env.local`, `google-services.json` ni `GoogleService-Info.plist`.
- Keystores de firma, contraseñas ni `android/key.properties`.

El repositorio no incluye claves reales. Los valores públicos actuales están en `lib/data/supabase_config.dart` y `lib/data/google_auth_config.dart`; reemplázalos si usas otro proyecto.

## Google Maps en Android

La API key de Maps se inyecta en el build nativo, no en Dart.

1. En Google Cloud habilita `Maps SDK for Android` y la facturación.
2. Crea una API key y restringe su uso al paquete `com.example.salgo_app` con el SHA-1 correspondiente.
3. Copia `android/key.properties.example` a `android/key.properties`.
4. Reemplaza `TU_API_KEY_AQUI` por tu key de desarrollo.

`android/key.properties` está en `.gitignore`: nunca lo subas. Si el archivo no existe, el build funciona pero el mapa se verá gris porque el manifest recibe una key vacía.

## Google Sign-In

1. En Google Cloud configura la pantalla de consentimiento OAuth y crea un cliente OAuth de tipo Web.
2. Crea también un cliente OAuth de Android usando el paquete `com.example.salgo_app` y el SHA-1 del keystore que uses.
3. Copia el Web client ID en `lib/data/google_auth_config.dart`. Ese valor es público.
4. En Supabase > Authentication > Providers > Google habilita el proveedor, usa el Web client ID y activa `Skip nonce check`.
5. Si la app de OAuth está en estado de prueba, agrega como usuarios de prueba las cuentas que iniciarán sesión.
6. Verifica que `salgo://auth` esté permitido como URL de redirección. El filtro ya está declarado en `android/app/src/main/AndroidManifest.xml`.

Para obtener el SHA-1 de debug usa tu herramienta habitual de Android/Java, por ejemplo `keytool` con el keystore de debug. Si compilas con otro keystore, registra también ese SHA-1.

## Build de release

`android/app/build.gradle.kts` firma actualmente el build de release con el keystore de debug para que la demostración universitaria pueda compilarse sin secretos:

```bash
flutter build apk --release
```

Antes de publicar en una tienda, reemplaza esa configuración por un keystore propio y nunca versiones el archivo ni sus contraseñas.

## iOS

El proyecto está enfocado y probado en Android. iOS no ha sido probado y no se garantiza su compilación sin configuración adicional nativa.

## Solución de problemas

- Mapa gris: revisa `android/key.properties`, que `Maps SDK for Android` esté habilitado, la facturación activa y que la key acepte el SHA-1 usado.
- Google Sign-In falla: revisa el Web client ID, el SHA-1, los usuarios de prueba, `Skip nonce check` y la URL `salgo://auth`.
- Error de RLS en Supabase: ejecuta `supabase/schema.sql` y confirma que la sesión sea `authenticated`.
- Datos que no sincronizan: verifica la publishable key y las políticas de la tabla correspondiente.
- Ubicación sin respuesta: activa GPS y permisos de la app; algunos emuladores no proveen coordenadas reales.
- Fallo de build después de cambiar dependencias: ejecuta `flutter clean`, `flutter pub get` y vuelve a compilar.
