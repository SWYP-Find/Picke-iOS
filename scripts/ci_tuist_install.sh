#!/usr/bin/env bash
# Tuist 의존성 설치 + 프로젝트 생성. bitrise.yml 의 모든 워크플로가 이 스크립트를 공유한다.
#
# SwiftPM 은 바이너리 아티팩트를 병렬로 내려받고 개별 요청에 타임아웃이 없다.
# 이 프로젝트 아티팩트는 3.7GB(sentry-cocoa 2.8GB, grpc-binary 609MB) 라서,
# 고정 900s 벽시계로 끊으면 18개 중 하나도 완료되지 못한 채 죽는다. 완료분이 없으면
# SwiftPM 아티팩트 캐시에도 남지 않아 재시도가 매번 0에서 다시 시작한다. (build #25)
#
# - 동시 요청 수를 줄여 아티팩트를 하나씩 확실히 끝내고 캐시에 남긴다
#   → 재시도는 남은 것만 이어받는다
# - 벽시계 대신 "내려받은 아티팩트 크기가 늘지 않음" 으로 정지를 판정한다
#   → 느린 것(계속 진행)과 멈춘 것(끊어야 함)을 구분한다
set -euo pipefail

: "${TUIST_VERSION:?TUIST_VERSION 이 필요하다}"

TOTAL_BUDGET="${TUIST_INSTALL_BUDGET:-2700}"  # 재시도까지 포함한 install 전체 상한
STALL_LIMIT="${TUIST_INSTALL_STALL:-300}"     # 이 시간 동안 진행이 없으면 정지로 본다
PROBE_INTERVAL=30

SPM_ARTIFACTS="$HOME/Library/Caches/org.swift.swiftpm/artifacts"

curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"
mise install "tuist@${TUIST_VERSION}"

export SWIFTPM_MAX_CONCURRENT_OPERATIONS="${SWIFTPM_MAX_CONCURRENT_OPERATIONS:-2}"

# 진행량 = 내려받아 놓인 아티팩트 총량(로컬 .build + SwiftPM 공유 캐시)
artifact_kb() {
  du -sk Tuist/.build/artifacts "$SPM_ARTIFACTS" 2>/dev/null |
    awk '{ sum += $1 } END { print sum + 0 }'
}

# 락을 물고 있을 수 있는 잔존 프로세스 정리. 이게 없으면 재시도가 무의미해진다.
release_spm_lock() {
  pkill -9 -f 'TuistTool.swift' 2>/dev/null || true
  pkill -9 -f 'swift-build|swift-package|swiftpm' 2>/dev/null || true
  sleep 5
}

# set -m 으로 자체 프로세스 그룹에 띄운다. mise exec 만 죽이면 자식 swift 가 살아남아
# Tuist/.build 락을 계속 물고, 다음 시도가 "Another instance of SwiftPM is already
# running" 으로 락을 기다리다 또 타임아웃된다.
run_install() {
  local limit="$1"
  set -m
  mise exec "tuist@${TUIST_VERSION}" -- swift TuistTool.swift install &
  local pid=$!
  set +m

  local waited=0 stalled=0 last now rc=0
  last=$(artifact_kb)
  while kill -0 "$pid" 2>/dev/null; do
    sleep "$PROBE_INTERVAL"
    waited=$((waited + PROBE_INTERVAL))
    now=$(artifact_kb)
    if [ "$now" -gt "$last" ]; then
      stalled=0
    else
      stalled=$((stalled + PROBE_INTERVAL))
    fi
    last="$now"
    if [ $((waited % 120)) -eq 0 ]; then
      echo "… install ${waited}s · 아티팩트 $((now / 1024))MB · 정지 ${stalled}s/${STALL_LIMIT}s · 남은 예산 $((limit - waited))s"
    fi
    if [ "$stalled" -ge "$STALL_LIMIT" ] || [ "$waited" -ge "$limit" ]; then
      if [ "$stalled" -ge "$STALL_LIMIT" ]; then
        echo "⏱️ ${STALL_LIMIT}s 동안 진행 없음 — 프로세스 그룹 종료"
      else
        echo "⏱️ 예산 ${limit}s 소진 — 프로세스 그룹 종료"
      fi
      kill -9 -"$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
  done
  wait "$pid" || rc=$?
  return $rc
}

started=$SECONDS
installed=0
for attempt in 1 2 3; do
  remaining=$((TOTAL_BUDGET - (SECONDS - started)))
  if [ "$remaining" -lt 120 ]; then
    echo "남은 예산 ${remaining}s — 재시도 중단"
    break
  fi
  echo "▶️ tuist install 시도 ${attempt}/3 (예산 ${remaining}s · 아티팩트 $(($(artifact_kb) / 1024))MB 확보)"
  if run_install "$remaining"; then
    installed=1
    break
  fi
  release_spm_lock
done

if [ "$installed" -ne 1 ]; then
  echo "❌ tuist install 실패 — 아티팩트 $(($(artifact_kb) / 1024))MB 까지 확보"
  exit 1
fi

mise exec "tuist@${TUIST_VERSION}" -- swift TuistTool.swift generate
