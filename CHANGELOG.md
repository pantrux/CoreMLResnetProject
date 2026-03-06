# Changelog

## [1.1.0] - 2026-03-06
### Added
- README técnico con guía de uso y alcance del proyecto.
- `RELEASE_CHECKLIST.md` para estandarizar salida a producción.

### Fixed
- Corrección de tipos `UIScene` mal escritos en `SceneDelegate` (`UISene` -> `UIScene`).
- Manejo de errores en clasificación para evitar `force unwrap` en errores de Vision.
- Mensajes de error más claros cuando falla la clasificación de imagen.

### Improved
- Código más defensivo al procesar resultados de `VNRequest`.
