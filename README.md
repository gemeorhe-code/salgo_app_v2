# salgo_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuración de Google Maps (Android)

La app usa `google_maps_flutter`, que necesita la API key en el build nativo
(no en código Dart).

1. Copia `android/key.properties.example` a `android/key.properties`.
2. Reemplaza `TU_API_KEY_AQUI` por tu key de desarrollo. En Google Cloud deben
   estar habilitados `Maps SDK for Android` y la facturación.
3. `android/key.properties` está en `.gitignore`: nunca lo subas al repositorio.

Si el archivo no existe, el build sigue funcionando, pero el mapa se verá gris
porque el manifest recibe una key vacía.
