# CI Trigger Matrix + Runbook (PR-25)

Objetivo: tener una guía **reproducible** para diagnosticar cuando los workflows de GitHub Actions no se disparan o se comportan de forma intermitente.

## Scope

Workflows cubiertos:
- `.github/workflows/ci-liveness.yml` (Ubuntu, barato)
- `.github/workflows/ios-build.yml` (macOS, caro)
- `.github/workflows/post-merge-ci-evidence.yml` (Ubuntu, snapshot + validación post-merge)

## Trigger Matrix

| Evento | ci-liveness | ios-build | Resultado esperado |
|---|---:|---:|---|
| `pull_request` | ✅ | ✅ | Ambos aparecen en la PR |
| `push` a `main` | ✅ | ✅ | Ambos aparecen en el commit de `main` |
| `workflow_dispatch` | ✅ | ✅ | Ejecutables manualmente para recuperación/diagnóstico |

## Runbook rápido (5-10 min)

### 1) Verifica que el commit esté en `main`

```bash
git log --oneline -n 5
```

### 2) Confirma que workflows estén activos

```bash
# En repos privados, usa GH_TOKEN. En públicos, también se recomienda para evitar límites.
export GH_TOKEN="<token>"

curl -sS --fail \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/pantrux/CoreMLResnetProject/actions/workflows \
  | jq -r '.workflows[] | [.name, .state, .path] | @tsv'
```

### 3) Si falta run por `push`, lanza recuperación manual

```bash
# Requiere GH_TOKEN con permisos repo/workflow
export GH_TOKEN="<token>"

curl -sS --fail -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/pantrux/CoreMLResnetProject/actions/workflows/ci-liveness.yml/dispatches \
  -d '{"ref":"main"}'

curl -sS --fail -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/pantrux/CoreMLResnetProject/actions/workflows/ios-build.yml/dispatches \
  -d '{"ref":"main", "inputs": {"reason":"manual-recovery"}}'
```

### 4) Recolecta evidencia en JSON (recomendado)

```bash
export GH_TOKEN="<token>"
bash scripts/ci_trigger_probe.sh
```

Artifacts generados en `ci-evidence/`:
- `workflows-<timestamp>.json`
- `runs-liveness-<timestamp>.json`
- `runs-ios-build-<timestamp>.json`
- `summary-<timestamp>.md`

Artifacts automáticos post-merge (workflow `Post-merge CI Evidence`):
- `ci-evidence/post-merge/<timestamp>/snapshot.json`
- `ci-evidence/post-merge/<timestamp>/summary.md`

Validación mínima post-merge:
- Debe existir al menos 1 run `push` en `ci-liveness` para el `HEAD_SHA` mergeado.
- Debe existir al menos 1 run `push` en `ios-build` para el mismo `HEAD_SHA`.
- Si alguna condición falla, el workflow post-merge marca error para alertar regresión de triggers.

## Diagnóstico por síntomas

### Síntoma A: corre `ci-liveness`, no corre `ios-build`
Probable causa: cola/runners macOS saturados o retraso de scheduling.

Acción:
1. Revisar estado de runs recientes de `ios-build`.
2. Disparar `workflow_dispatch` en `ios-build`.
3. Esperar 3-5 min y volver a consultar.

### Síntoma B: no corre ninguno (`liveness` + `ios-build`)
Probable causa: problema de trigger/evento o workflow deshabilitado.

Acción:
1. Verificar que workflows estén `active`.
2. Validar que el evento realmente ocurrió sobre `main`.
3. Ejecutar dispatch manual en ambos y capturar evidencia.

### Síntoma C: `ios-build` falla pero `liveness` success
Probable causa: problema funcional en pipeline iOS, no de trigger.

Acción:
1. Descargar artifact `ios-ci-diagnostics-*`.
2. Revisar `ci-logs/*` y `test-results.xcresult`.
3. Corregir en PR, no tocar triggers.

## Criterio de salida (Done)

Se considera incidente de trigger cerrado cuando:
- se observa al menos 1 run exitoso de `ci-liveness` y 1 run de `ios-build`
- ambos asociados al evento investigado o a recovery `workflow_dispatch`
- se guarda evidencia en `ci-evidence/` (JSON + summary)
