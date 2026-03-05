# CoreMLResnetProject

App iOS (UIKit) minimal para **clasificar imágenes** usando **Core ML + Vision** con el modelo `Resnet50.mlmodel`.

## ✅ Qué incluye

- Proyecto listo para abrir en Xcode: `CoreMLProject.xcodeproj`
- Código fuente:
  - `CoreMLProject/AppDelegate.swift`
  - `CoreMLProject/SceneDelegate.swift`
  - `CoreMLProject/ViewController.swift`
- Recursos:
  - `CoreMLProject/Resnet50.mlmodel`
  - `CoreMLProject/Info.plist` (incluye `NSPhotoLibraryUsageDescription`)
  - `CoreMLProject/Assets.xcassets` (AppIcon placeholder)

## Requisitos

- macOS con Xcode
- iOS Simulator o device

## Cómo ejecutar

1) Abre `CoreMLProject.xcodeproj` en Xcode.
2) Selecciona un simulador (o device).
3) Run.
4) En la app:
   - “Seleccionar Imagen” → elige una imagen de tu Photo Library
   - “Clasificar Imagen” → verás el top-2 de resultados + % confianza

## Notas técnicas

- Vision usa `VNCoreMLRequest` con `imageCropAndScaleOption = .centerCrop` (el modelo espera `224x224`).
- Inferencia en background, UI update en main.

## Git LFS (recomendado)

El archivo `.mlmodel` es grande. Si vas a iterar con modelos o el repo crece, conviene usar Git LFS:

```bash
git lfs install
git lfs track "*.mlmodel"
```

Este repo incluye `.gitattributes` con la regla recomendada.

## CI

Hay un workflow (`.github/workflows/ios-build.yml`) que compila el proyecto en `macos-latest` (simulador) con `CODE_SIGNING_ALLOWED=NO`.

## Licencia

No especificada. (Recomendado: añadir `LICENSE` si se va a compartir públicamente.)
