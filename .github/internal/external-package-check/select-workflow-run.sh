#!/usr/bin/env bash
set -euo pipefail

dispatched_at=""
target_ref=""
bot_login=""

while (($# > 0)); do
  case "$1" in
    --dispatched-at)
      dispatched_at="$2"
      shift 2
      ;;
    --target-ref)
      target_ref="$2"
      shift 2
      ;;
    --bot-login)
      bot_login="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${dispatched_at}" || -z "${target_ref}" ]]; then
  echo "--dispatched-at and --target-ref are required." >&2
  exit 1
fi

jq -r \
  --arg dispatched_at "${dispatched_at}" \
  --arg target_ref "${target_ref}" \
  --arg bot_login "${bot_login}" \
  '[
    .workflow_runs[]
    | select(.created_at >= $dispatched_at)
    | select(.event == "workflow_dispatch")
    | select(.head_branch == $target_ref)
  ]
  | sort_by(.created_at)
  | (
      map(select(($bot_login != "") and ((.triggering_actor.login // .actor.login // "") == $bot_login)))
      | first
    ) // first
  | .id // empty'