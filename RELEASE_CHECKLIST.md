# Release Checklist (v1.1.0)

## 1) Calidad de código
- [x] Compilación local sin errores de tipos en ciclo de vida (`UIScene`).
- [x] Sin `force unwrap` en rutas de error críticas.
- [x] Manejo de errores legible para usuario.

## 2) Funcionalidad
- [x] Selección de imagen habilita botón de clasificación.
- [x] Clasificación muestra top-2 resultados.
- [x] Estado de UI actualizado durante inferencia.

## 3) Release assets
- [x] `README.md` actualizado.
- [ ] `CHANGELOG.md` generado para v1.1.0 (pendiente mover cambios desde `[Unreleased]` a sección versionada en corte de release).
- [ ] Tag release `v1.1.0`.
- [ ] Publicar release notes en remoto.

## 4) Verificación final
- [ ] Smoke test en dispositivo real.
- [ ] Confirmar permiso de Photo Library en runtime.
- [ ] Capturas de pantalla para documentación.
