# CoreMLResnetProject

App iOS de ejemplo para clasificación de imágenes usando **Core ML + Vision** con el modelo **ResNet-50**.

## Estado
- Objetivo de release: **v1.1.0**
- Estado actual: **release-readiness**

## Funcionalidades
- Selección de imagen desde la galería.
- Clasificación con `VNCoreMLRequest`.
- Muestra de top-2 predicciones con porcentaje de confianza.

## Requisitos
- Xcode 15+
- iOS 15+
- Swift 5.9+

## Estructura
- `AppDelegate.swift`: ciclo de vida app.
- `SceneDelegate.swift`: bootstrap de ventana principal.
- `ViewController.swift`: UI y flujo de inferencia ML.
- `Resnet50.mlmodel`: modelo Core ML.

## Ejecución
1. Abre el proyecto en Xcode.
2. Ejecuta en simulador/dispositivo.
3. Presiona **Seleccionar Imagen**.
4. Presiona **Clasificar Imagen**.

## Notas de Release v1.1.0
- Corrección de firmas `UIScene` en `SceneDelegate`.
- Manejo defensivo de errores durante inferencia.
- Documentación de release y changelog.
