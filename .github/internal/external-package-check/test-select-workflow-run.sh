#!/usr/bin/env bash
set -euo pipefail

action_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

selected_run_id="$(bash "${action_dir}/select-workflow-run.sh" \
  --dispatched-at "2026-04-27T19:46:53Z" \
  --target-ref "main" \
  --bot-login "posit-shiny-automation[bot]" \
  < "${action_dir}/testdata/workflow-runs.json")"

if [[ "${selected_run_id}" != "25015944788" ]]; then
  echo "Expected run 25015944788, got ${selected_run_id:-<empty>}." >&2
  exit 1
fi