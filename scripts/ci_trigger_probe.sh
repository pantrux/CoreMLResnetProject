#!/usr/bin/env bash
set -euo pipefail

REPO="pantrux/CoreMLResnetProject"
OUT_DIR="ci-evidence"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "[ci-trigger-probe] ERROR: GH_TOKEN no está definido"
  echo "[ci-trigger-probe] export GH_TOKEN=<token>"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[ci-trigger-probe] ERROR: jq no está instalado"
  echo "[ci-trigger-probe] instala jq (ej: brew install jq / apt-get install jq)"
  exit 1
fi

if curl --help all 2>/dev/null | grep -q -- '--fail-with-body'; then
  CURL_FAIL_FLAG='--fail-with-body'
else
  CURL_FAIL_FLAG='--fail'
fi

if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
  CURL_RETRY_ALL_ERRORS_FLAG='--retry-all-errors'
else
  CURL_RETRY_ALL_ERRORS_FLAG=''
fi

# Timeouts/retries to avoid hanging indefinitely on degraded network/API.
CURL_CONNECT_TIMEOUT="${CURL_CONNECT_TIMEOUT:-10}"
CURL_MAX_TIME="${CURL_MAX_TIME:-30}"
CURL_RETRY="${CURL_RETRY:-2}"

mkdir -p "$OUT_DIR"

api() {
  local path="$1"
  curl -sS "$CURL_FAIL_FLAG" \
    --connect-timeout "$CURL_CONNECT_TIMEOUT" \
    --max-time "$CURL_MAX_TIME" \
    --retry "$CURL_RETRY" \
    --retry-delay 1 \
    ${CURL_RETRY_ALL_ERRORS_FLAG:+$CURL_RETRY_ALL_ERRORS_FLAG} \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${REPO}${path}"
}

echo "[ci-trigger-probe] fetching workflows..."
api "/actions/workflows" > "${OUT_DIR}/workflows-${TS}.json"

echo "[ci-trigger-probe] fetching recent liveness runs..."
api "/actions/workflows/ci-liveness.yml/runs?per_page=10" > "${OUT_DIR}/runs-liveness-${TS}.json"

echo "[ci-trigger-probe] fetching recent ios-build runs..."
api "/actions/workflows/ios-build.yml/runs?per_page=10" > "${OUT_DIR}/runs-ios-build-${TS}.json"

{
  echo "# CI Trigger Probe Summary (${TS})"
  echo
  echo "## Workflows"
  jq -r '.workflows[] | "- \(.name): state=\(.state), path=\(.path)"' "${OUT_DIR}/workflows-${TS}.json"

  echo
  echo "## Last runs: CI Liveness"
  jq -r '.workflow_runs[] | "- id=\(.id) status=\(.status) conclusion=\(.conclusion) event=\(.event) head_sha=\(.head_sha)"' "${OUT_DIR}/runs-liveness-${TS}.json"

  echo
  echo "## Last runs: iOS Build"
  jq -r '.workflow_runs[] | "- id=\(.id) status=\(.status) conclusion=\(.conclusion) event=\(.event) head_sha=\(.head_sha)"' "${OUT_DIR}/runs-ios-build-${TS}.json"
} > "${OUT_DIR}/summary-${TS}.md"

echo "[ci-trigger-probe] done"
echo "[ci-trigger-probe] artifacts:"
echo "- ${OUT_DIR}/workflows-${TS}.json"
echo "- ${OUT_DIR}/runs-liveness-${TS}.json"
echo "- ${OUT_DIR}/runs-ios-build-${TS}.json"
echo "- ${OUT_DIR}/summary-${TS}.md"
