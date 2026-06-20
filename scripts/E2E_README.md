# Picke E2E / 스모크 테스트

## 환경 제약 (중요)

iOS 26.3 / Xcode 26 시뮬레이터에서 **maestro 는 동작하지 않는다.**

- maestro 2.6.1: 시스템 정보 로깅 직후 시작 단계에서 hang
- maestro 1.39: XCUITest 드라이버 러너는 설치되나 gRPC 채널이 alive 되지 않음
  (`ensureOpen() ... is channel alive?: false` 반복 재시도)

→ maestro 가 iOS 26 을 지원하기 전까지는 **idb 기반 스크립트**로 e2e 를 돌린다.

## idb 기반 e2e 스모크 (현재 사용)

```bash
# 사전: 부팅된 시뮬레이터에 앱 설치 + 로그인 세션
Scripts/e2e_smoke_idb.sh <UDID>
```

검증 범위 (9 단계, PASS/FAIL 출력 + 스크린샷 `/tmp/maestro/shots`):
1. 홈 렌더 (QA-41 Best 배틀)
2. 알림 모두읽음 빨간점 (QA-47)
3. 마이페이지 진입 (딥링크 우회)
4. 설정 → 회원탈퇴 → 확인팝업 노출 (QA-48) + 취소버튼 "뒤로가기" (Figma 5541)
5. 댓글/관점 화면 (QA-22/44, 투표게이트 딥링크 우회)

### 커스텀 탭바 한계

홈 스크롤 콘텐츠가 반투명 탭바 위 히트영역을 가려, idb 합성 탭으로는
탭바(홈/탐색/빠른배틀/마이) 버튼이 안 눌린다. 따라서 탭 전환이 필요한
플로우(탐색 QA-39, 빠른배틀 QA-46)는 idb 로 진입 불가하며 `picke://` 딥링크가
없는 화면은 검증에서 제외된다. maestro(XCUITest)는 히트테스트가 정확해 이
문제가 없으므로, 환경이 지원되면 `Scripts/maestro/smoke.yaml` 로 전체 탭 순회를 검증한다.

## 딥링크 (수동 네비게이션용)

```bash
xcrun simctl openurl <UDID> "picke://point"               # 마이페이지(포인트 내역)
xcrun simctl openurl <UDID> "picke://perspective/<id>"    # 댓글/관점 화면
xcrun simctl openurl <UDID> "picke://battle/<id>"         # 배틀(투표 게이트 시 토스트)
```
