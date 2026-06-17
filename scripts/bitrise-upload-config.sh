#!/usr/bin/env bash
# bitrise.yml 을 repo 에 커밋하지 않고 Bitrise 앱에 업로드한다.
# 사용: BITRISE_TOKEN=... BITRISE_APP_SLUG=... ./scripts/bitrise-upload-config.sh
#  - BITRISE_TOKEN     : Bitrise Personal Access Token (계정 → Security → API tokens)
#  - BITRISE_APP_SLUG  : 앱 슬러그 (앱 URL /app/<slug> 또는 앱 설정에서 확인)
set -euo pipefail

: "${BITRISE_TOKEN:?BITRISE_TOKEN 환경변수가 필요합니다}"
: "${BITRISE_APP_SLUG:?BITRISE_APP_SLUG 환경변수가 필요합니다}"

YML_PATH="$(dirname "$0")/../bitrise.yml"
[ -f "$YML_PATH" ] || { echo "bitrise.yml 없음: $YML_PATH"; exit 1; }

# yaml 내용을 JSON 문자열로 안전 인코딩 (python3 사용)
payload=$(python3 - "$YML_PATH" <<'PY'
import json, sys
yml = open(sys.argv[1], encoding="utf-8").read()
print(json.dumps({"app_config_datastore_yaml": yml}))
PY
)

echo "→ Bitrise 앱($BITRISE_APP_SLUG)에 bitrise.yml 업로드..."
http=$(curl -sS -o /tmp/bitrise_cfg_resp.json -w "%{http_code}" \
  -X POST "https://api.bitrise.io/v0.1/apps/${BITRISE_APP_SLUG}/bitrise.yml" \
  -H "Authorization: ${BITRISE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$payload")

if [ "$http" = "200" ]; then
  echo "✅ 업로드 성공 (config 가 Bitrise 에 저장됨, repo 미포함)"
else
  echo "❌ 실패 (HTTP $http)"; cat /tmp/bitrise_cfg_resp.json; exit 1
fi
