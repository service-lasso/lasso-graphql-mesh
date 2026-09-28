#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

for path in \
  "$ROOT/service.json" \
  "$ROOT/verify/service-harness.json"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
done

SERVICE_ID=$(python3 - <<'PY'
import json, pathlib
path = pathlib.Path('service.json')
print(json.loads(path.read_text())['id'])
PY
)
if [[ "$SERVICE_ID" != "graphql-mesh" ]]; then
  echo "service.json id mismatch" >&2
  exit 1
fi

python3 - <<'PY'
import json
import pathlib

paths = [pathlib.Path('service.json')]
services_root = pathlib.Path('services')
if services_root.exists():
    paths.extend(sorted(services_root.glob('**/service.json')))

for path in paths:
    doc = json.loads(path.read_text())
    if 'healthcheck' in doc:
        raise SystemExit(f"Singular healthcheck is not allowed in {path}; use healthchecks[].")
    execconfig = doc.get('execconfig')
    if isinstance(execconfig, dict) and 'healthcheck' in execconfig:
        raise SystemExit(f"execconfig.healthcheck is not allowed in {path}; use top-level healthchecks[].")
    if 'healthchecks' in doc:
        checks = doc['healthchecks']
        if not isinstance(checks, list):
            raise SystemExit(f"healthchecks must be an array in {path}.")
        for check in checks:
            if not isinstance(check, dict) or not check.get('id'):
                raise SystemExit(f"Every healthchecks[] item needs a stable id in {path}.")
PY

CONTRACT_ID=$(python3 - <<'PY'
import json, pathlib
path = pathlib.Path('verify/service-harness.json')
print(json.loads(path.read_text())['serviceId'])
PY
)
if [[ "$CONTRACT_ID" != "graphql-mesh" ]]; then
  echo "service-harness.json serviceId mismatch" >&2
  exit 1
fi

node --check "$ROOT/runtime/start.mjs"
node --check "$ROOT/runtime/compose.mjs"
set +e
PREFLIGHT_OUTPUT=$(node "$ROOT/runtime/start.mjs" 2>&1)
PREFLIGHT_STATUS=$?
set -e
if [[ "$PREFLIGHT_STATUS" -ne 2 || "$PREFLIGHT_OUTPUT" != *"required file is missing"* ]]; then
  echo "Gateway preflight did not fail safely without a composed supergraph." >&2
  exit 1
fi

echo "GraphQL Mesh package tests passed"
