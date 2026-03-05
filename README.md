# CoreMLResnetProject

App iOS (UIKit) minimal para **clasificar imágenes** usando **Core ML + Vision** con el modelo `Resnet50.mlmodel`.

## ✅ Qué incluye

- Proyecto listo para abrir en Xcode: `CoreMLProject.xcodeproj`
- Código fuente:
  - `CoreMLProject/AppDelegate.swift`
  - `CoreMLProject/SceneDelegate.swift`
  - `CoreMLProject/ViewController.swift`
  - `CoreMLProject/ModelClassifierFactory.swift`
  - `CoreMLProject/ClassificationPresenter.swift`
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

## Git LFS (obligatorio para el modelo)

`Resnet50.mlmodel` se versiona con **Git LFS**.

Setup local recomendado:

```bash
./scripts/setup_model_assets.sh
```

Esto instala hooks LFS locales y descarga el modelo.

Si prefieres manual:

```bash
git lfs install --local
git lfs pull --include="CoreMLProject/Resnet50.mlmodel"
```

Este repo incluye `.gitattributes` con la regla de tracking.

## Testing

La suite (`CoreMLProjectTests`) valida:

- Carga del request Core ML (`ModelClassifierFactory`)
- Formateo de salida top-2 para clasificación
- Casos edge de payload (`missingResults`, `invalidType`)
- Mensajes de error con y sin detalle
- **UI smoke tests** del `ViewController`:
  - estado inicial de botones/label
  - prompt al clasificar sin imagen
  - mensaje de modelo no disponible

## CI

Workflows:

- **iOS Build** (`.github/workflows/ios-build.yml`) ejecuta gates obligatorios en `macos-14`.
- **CI Liveness (fast)** (`.github/workflows/ci-liveness.yml`) corre en `ubuntu-latest` y sirve como *ping* barato para verificar que GitHub Actions está disparando eventos.

El workflow iOS (`.github/workflows/ios-build.yml`) ejecuta gates obligatorios en `macos-14`:

- Checkout con `lfs: true` + validación de tamaño del modelo
- SwiftLint (`.swiftlint.yml`)
- Build en iOS Simulator
- Build-for-testing
- Test en simulador real (strict mode, sin skip)
- Coverage gate mínimo (30%) sobre el target `CoreMLProject` usando `scripts/check_coverage.py`

Además sube artefactos de diagnóstico (`ci-logs`) con logs, `xcresult` y reporte de cobertura para troubleshooting.

Hardening anti-stuck aplicado en CI:
- `concurrency` por PR/ref con `cancel-in-progress: true` para evitar colas de runs obsoletos sin colisiones involuntarias entre eventos.
- Trigger manual `workflow_dispatch` disponible para diagnóstico/recuperación rápida de CI, con input opcional `reason` para trazabilidad.
- `timeout-minutes` en job y pasos críticos (build/build-for-testing/test/detect simulator/install swiftlint).
- `-destination-timeout 120` en comandos `xcodebuild` relevantes.
- En fallos de test, se adjunta `simctl list devices` en logs para diagnóstico rápido.

Diagnóstico rápido (si no ves runs en `push`):
- Si **CI Liveness (fast)** sí corre pero **iOS Build** no: dispara `iOS Build` manualmente con `workflow_dispatch` e investiga cola/runner.
- Si **ninguno** corre: probablemente el workflow está deshabilitado a nivel repo o hay un incidente de GitHub Actions; re-habilitar el workflow y reintentar.

## Release management

- `VERSION`: versión semántica vigente del proyecto (`x.y.z`, opcional `-prerelease` y `+build`).
- `CHANGELOG.md`: historial de cambios (Keep a Changelog).
- `docs/RELEASE.md`: checklist operativa de release.
- `scripts/version_sync.py`: sincroniza/valida versión iOS (`MARKETING_VERSION` y `CFBundleShortVersionString`) usando el core `x.y.z` de `VERSION`.
- CI incluye **Release metadata gate** + **Version sync gate** para validar formato/versionado y evitar drift entre metadata de release y app bundle.

## Licencia

MIT (`LICENSE`).
