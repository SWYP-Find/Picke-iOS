#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_PATH="${1:-${SENTRY_ARCHIVE_PATH:-${ARCHIVE_PATH:-}}}"
SENTRY_ORG="${SENTRY_ORG:-picke}"
SENTRY_PROJECT="${SENTRY_PROJECT:-picke-ios}"

if ! command -v sentry-cli >/dev/null 2>&1; then
  echo "error: sentry-cli 가 필요합니다: brew install getsentry/tools/sentry-cli" >&2
  exit 127
fi

if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]]; then
  echo "error: SENTRY_AUTH_TOKEN 이 필요합니다." >&2
  exit 1
fi

if [[ -z "$ARCHIVE_PATH" || ! -d "$ARCHIVE_PATH" ]]; then
  echo "error: xcarchive 경로가 필요합니다. 사용법: scripts/sentry-size-analysis.sh path/to/Picke.xcarchive" >&2
  exit 1
fi

sentry-cli build upload "$ARCHIVE_PATH" \
  --org "$SENTRY_ORG" \
  --project "$SENTRY_PROJECT"
