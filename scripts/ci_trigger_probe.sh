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

mkdir -p "$OUT_DIR"

api() {
  local path="$1"
  curl -sS --fail-with-body \
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
