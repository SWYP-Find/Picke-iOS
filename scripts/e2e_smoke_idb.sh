#!/usr/bin/env bash
#
# e2e_smoke_idb.sh
# Picke iOS e2e 스모크 테스트 (idb 기반).
#
# 배경: iOS 26.3 / Xcode 26 시뮬레이터에서 maestro 의 XCUITest 드라이버 채널이
#       연결되지 않아(2.x 는 시작 단계 hang, 1.39 는 channel-alive 실패) maestro 대신
#       idb 로 시뮬레이터를 직접 구동한다. 커스텀 탭바(홈/탐색/빠른배틀/마이)는 홈 스크롤
#       콘텐츠가 반투명 탭바 위 히트영역을 가려 idb 합성 탭이 안 먹으므로, 탭 전환이 필요한
#       플로우는 picke:// 딥링크로 우회한다.
#
# 사용법: Scripts/e2e_smoke_idb.sh [UDID]
#   사전: 앱이 설치되어 있고 로그인 세션이 있는 부팅된 시뮬레이터.
#
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

UDID="${1:-04D0EE67-057B-4705-B518-EAA3900E8195}"
APP="io.Picke.co"
SHOTS="/tmp/maestro/shots"
mkdir -p "$SHOTS"

PASS=0; FAIL=0
shot() { xcrun simctl io "$UDID" screenshot "$SHOTS/$1.png" >/dev/null 2>&1; }

# 접근성 라벨로 요소 중심좌표 출력 (부분일치). 없으면 빈 문자열.
center_of() {
  idb ui describe-all --udid "$UDID" 2>/dev/null | python3 -c "
import sys,json
key=sys.argv[1]
for e in json.load(sys.stdin):
    l=(e.get('AXLabel') or '')
    if key in l:
        f=e.get('frame',{})
        print(int(f.get('x',0)+f.get('width',0)/2), int(f.get('y',0)+f.get('height',0)/2)); break
" "$1" 2>/dev/null
}

tap_label() {
  local c; c=$(center_of "$1")
  if [ -n "$c" ]; then idb ui tap --udid "$UDID" $c >/dev/null 2>&1; return 0; fi
  return 1
}

assert_present() { # $1=label $2=step
  local c; c=$(center_of "$1")
  if [ -n "$c" ]; then echo "  ✅ PASS [$2] '$1' 노출"; PASS=$((PASS+1)); return 0
  else echo "  ❌ FAIL [$2] '$1' 미노출"; FAIL=$((FAIL+1)); return 1; fi
}

deeplink() { # picke:// 딥링크 + '열기' 다이얼로그 자동 확인
  xcrun simctl openurl "$UDID" "$1" >/dev/null 2>&1; sleep 1
  tap_label "열기" >/dev/null 2>&1; sleep 2
}

echo "=== Picke e2e 스모크 (idb, $UDID) ==="
xcrun simctl launch "$UDID" "$APP" >/dev/null 2>&1; sleep 4

echo "[1] 홈 진입"
shot "01_home"; assert_present "Best 배틀" "홈렌더(QA-41)"

echo "[2] 알림 — 모두읽음 빨간점 (QA-47)"
tap_label "알림" || idb ui tap --udid "$UDID" 339 78 >/dev/null 2>&1; sleep 2
assert_present "모두 읽음" "알림진입"
tap_label "모두 읽음"; sleep 2; shot "02_noti_read"
tap_label "뒤로" >/dev/null 2>&1; sleep 1; shot "02_home_back"

echo "[3] 마이페이지 (딥링크 우회)"
deeplink "picke://point"; assert_present "포인트" "포인트내역"
tap_label "뒤로" >/dev/null 2>&1; sleep 2; shot "03_mypage"
assert_present "철학자 유형" "마이페이지(QA-45)"

echo "[4] 설정 → 회원탈퇴 → 확인팝업 (QA-48 + Figma5541)"
idb ui tap --udid "$UDID" 347 82 >/dev/null 2>&1; sleep 2   # 설정 기어
assert_present "회원 탈퇴" "설정진입"
tap_label "회원 탈퇴"; sleep 2
assert_present "제출하기" "탈퇴사유화면"
tap_label "자주 이용하지 않아요"; sleep 1
tap_label "제출하기"; sleep 2; shot "04_withdraw_popup"
assert_present "탈퇴하시겠습니까" "탈퇴팝업노출(QA-48)"
assert_present "뒤로가기" "취소버튼문구=뒤로가기(Figma5541)"
tap_label "뒤로가기"; sleep 1   # 실제 탈퇴 안 함

echo "[5] 댓글/관점 화면 (딥링크, 투표게이트 우회)"
deeplink "picke://perspective/1"; shot "05_comment"
assert_present "답글" "댓글화면(QA-22/44)"

echo ""
echo "=== 결과: PASS=$PASS / FAIL=$FAIL ==="
echo "스크린샷: $SHOTS"
[ "$FAIL" -eq 0 ]
