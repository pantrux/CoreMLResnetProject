#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
SHA="${GITHUB_SHA:?GITHUB_SHA is required}"
SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
RUN_URL="${SERVER_URL}/${REPO}/actions/runs/${GITHUB_RUN_ID:-unknown}"
OUT_BASE="${1:-ci-evidence/post-merge}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${OUT_BASE}/${TS}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "[post-merge-ci-snapshot] ERROR: GITHUB_TOKEN is required"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[post-merge-ci-snapshot] ERROR: jq is required"
  exit 1
fi

mkdir -p "$OUT_DIR"

api() {
  local path="$1"
  curl -sS --fail \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${REPO}${path}"
}

workflows_json="${OUT_DIR}/workflows.json"
runs_liveness_json="${OUT_DIR}/runs-ci-liveness.json"
runs_ios_json="${OUT_DIR}/runs-ios-build.json"
snapshot_json="${OUT_DIR}/snapshot.json"
summary_md="${OUT_DIR}/summary.md"

api "/actions/workflows" > "$workflows_json"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-10}"
SLEEP_SECONDS="${SLEEP_SECONDS:-15}"

validation="failed"
liveness_push_for_sha=0
ios_push_for_sha=0

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  echo "[post-merge-ci-snapshot] polling runs attempt ${attempt}/${MAX_ATTEMPTS}"

  api "/actions/workflows/ci-liveness.yml/runs?per_page=100" > "$runs_liveness_json"
  api "/actions/workflows/ios-build.yml/runs?per_page=100" > "$runs_ios_json"

  liveness_push_for_sha=$(jq --arg sha "$SHA" '[.workflow_runs[] | select(.event == "push" and .head_sha == $sha)] | length' "$runs_liveness_json")
  ios_push_for_sha=$(jq --arg sha "$SHA" '[.workflow_runs[] | select(.event == "push" and .head_sha == $sha)] | length' "$runs_ios_json")

  if [[ "$liveness_push_for_sha" -ge 1 && "$ios_push_for_sha" -ge 1 ]]; then
    validation="passed"
    break
  fi

  if [[ "$attempt" -lt "$MAX_ATTEMPTS" ]]; then
    sleep "$SLEEP_SECONDS"
  fi
done

if [[ "$validation" != "passed" ]]; then
  echo "[post-merge-ci-snapshot] Trigger regression suspected for sha=${SHA}" >&2
  echo "[post-merge-ci-snapshot] ci-liveness push runs for sha: ${liveness_push_for_sha}" >&2
  echo "[post-merge-ci-snapshot] ios-build push runs for sha: ${ios_push_for_sha}" >&2
fi

jq -n \
  --arg generatedAt "$TS" \
  --arg repo "$REPO" \
  --arg sha "$SHA" \
  --arg runUrl "$RUN_URL" \
  --arg validation "$validation" \
  --argjson livenessPushForSha "$liveness_push_for_sha" \
  --argjson iosPushForSha "$ios_push_for_sha" \
  --slurpfile workflows "$workflows_json" \
  --slurpfile liveness "$runs_liveness_json" \
  --slurpfile ios "$runs_ios_json" \
  '{
    generatedAt: $generatedAt,
    repository: $repo,
    sha: $sha,
    workflowRunUrl: $runUrl,
    validation: {
      pushRunsOnCurrentSha: {
        ciLiveness: $livenessPushForSha,
        iosBuild: $iosPushForSha
      },
      status: $validation
    },
    workflows: ($workflows[0].workflows | map({name, path, state})),
    recentRuns: {
      ciLiveness: ($liveness[0].workflow_runs | map({
        id, name, status, conclusion, event, head_sha, run_started_at, created_at, updated_at, html_url
      })),
      iosBuild: ($ios[0].workflow_runs | map({
        id, name, status, conclusion, event, head_sha, run_started_at, created_at, updated_at, html_url
      }))
    }
  }' > "$snapshot_json"

{
  echo "# Post-merge CI Snapshot (${TS})"
  echo
  echo "- Repo: \`${REPO}\`"
  echo "- SHA: \`${SHA}\`"
  echo "- Workflow run: ${RUN_URL}"
  echo "- Validation status: **${validation}**"
  echo
  echo "## Trigger validation (push on current SHA)"
  echo "- ci-liveness push runs on SHA: ${liveness_push_for_sha}"
  echo "- ios-build push runs on SHA: ${ios_push_for_sha}"
  echo
  echo "## Workflows state"
  jq -r '.workflows[] | "- \(.name): state=\(.state), path=\(.path)"' "$snapshot_json"
  echo
  echo "## Recent ci-liveness runs"
  jq -r '.recentRuns.ciLiveness[] | "- id=\(.id) event=\(.event) status=\(.status) conclusion=\(.conclusion) started=\(.run_started_at)"' "$snapshot_json"
  echo
  echo "## Recent ios-build runs"
  jq -r '.recentRuns.iosBuild[] | "- id=\(.id) event=\(.event) status=\(.status) conclusion=\(.conclusion) started=\(.run_started_at)"' "$snapshot_json"
} > "$summary_md"

cat "$summary_md" >> "$GITHUB_STEP_SUMMARY"

echo "snapshot_dir=${OUT_DIR}" >> "$GITHUB_OUTPUT"

echo "[post-merge-ci-snapshot] snapshot_dir=${OUT_DIR}"

if [[ "$validation" != "passed" ]]; then
  exit 1
fi
