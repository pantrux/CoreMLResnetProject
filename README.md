# CoreMLResnetProject

Demo minimal (UIKit) para **clasificar imágenes** usando **Core ML + Vision** con el modelo `Resnet50.mlmodel`.

> Nota: este repo está pensado como “código fuente + modelo”. Para compilar y ejecutar necesitas un proyecto Xcode (`.xcodeproj`) o un workspace (`.xcworkspace`).

## Qué incluye

- `ViewController.swift` — UI + integración Vision (`VNCoreMLRequest`) para clasificar una imagen
- `AppDelegate.swift` / `SceneDelegate.swift` — bootstrap sin storyboard (root view controller por código)
- `Resnet50.mlmodel` — modelo CoreML

## Requisitos

- macOS con Xcode
- iOS target (simulador o device)

## Cómo usarlo (paso a paso)

1) **Crear proyecto UIKit**

- Xcode → File → New → Project → iOS → *App*
- Interface: **Storyboard** o **SwiftUI** (da igual, luego lo sobreescribimos)
- Language: **Swift**

2) **Copiar los archivos de este repo**

- Copia `AppDelegate.swift`, `SceneDelegate.swift`, `ViewController.swift` al proyecto (reemplaza los existentes si aplica).
- Arrastra `Resnet50.mlmodel` al proyecto (asegúrate de marcar “Copy items if needed”).

3) **Agregar permisos en Info.plist**

La app abre la galería (Photo Library). Agrega:

- `NSPhotoLibraryUsageDescription` → por ejemplo: `Necesitamos acceso a tu galería para clasificar imágenes.`

Sin este permiso iOS puede crashear al abrir el picker.

4) **Ejecutar**

- Run en simulador o dispositivo
- “Seleccionar Imagen” → elige una
- “Clasificar Imagen” → verás el top-2 de resultados con confianza

## Notas técnicas

- El modelo espera `224x224`, por eso se usa:
  - `request.imageCropAndScaleOption = .centerCrop`
- La inferencia se corre en background y el UI se actualiza en main thread.

## Buenas prácticas recomendadas

- Considerar mover el modelo a **Git LFS** si el repo crece (el `.mlmodel` es grande).
- Agregar tests (al menos smoke) y CI cuando el proyecto Xcode exista en el repo.

## Licencia

No especificada. (Recomendado: añadir `LICENSE` si se va a compartir públicamente.)
