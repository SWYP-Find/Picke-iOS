# 리뷰 지침

Codex PR 리뷰 · 로컬 리뷰 에이전트 · 사람이 함께 읽는다. 세부 코드 규칙의 원본은 `AGENTS.md`이고, 이 파일은 심각도와 범위만 정한다.

## 심각도 기준

- 높음: 동작이 깨짐 · 화면 전환이 막힘 · 개인정보(이름 · 이메일 · 전화번호 · 토큰)가 로그 · Mixpanel · Firebase로 나감 · 되돌리기 어려운 변경(저장소 키 · 공개 Interface 타입 · 배포 설정).
- 중간: `CLAUDE.md` Hard 규칙 위반, `AGENTS.md` "(필수)" 규칙 위반, 테스트 없는 동작 변경, Android 대조 기록과 다른 동작.
- 낮음(Nit): 이름 · 구조 제안. 리뷰 한 번에 최대 5개.

## 지적하지 않는 것

- SwiftFormat이 정하는 포맷. 기존 파일은 일괄 포맷되어 있지 않으므로 바꾼 줄 밖의 포맷은 보지 않는다.
- Tuist 생성물(`Derived/`, `.xcodeproj`, `.xcworkspace`), `Package.resolved`
- 디자인 토큰 생성 파일(`Tools/TokenGenerator.swift`가 만드는 코드)
- fastlane이 고치는 빌드 번호 파일(`Plugins/.../Project+Templete/Extension+String.swift`)
- `docs/` 아래 조사 · 대조 기록의 문체

## 항상 확인

- Feature가 Repository · Domain 구현 · 네트워크 모듈에 직접 의존하지 않는가 (UseCase만)
- 화면 전환이 App의 Coordinator로만 이뤄지고, 자식 Feature는 `delegate`로 알리는가
- 화면에 보이는 값이 State computed property로 정리되고 `body` 안 인라인 계산이 없는가
- 화면 전용 모델이 같은 모듈 `Model/` 폴더의 최상위 타입인가
- 자식 2개 이상 서브뷰는 `@ViewBuilder func`, 폰트 · 색은 디자인 토큰인가
- 취소 가능한 effect(재생 · 타이머 · 폴링)가 화면을 떠날 때 취소되는가
- 하네스 파일(`.claude/hooks` · `.claude/scripts` · `.githooks` · `.claude/settings.json`)을 바꿨다면 게이트를 약하게 만들지 않았는가
- `.claude/known-test-failures.txt`에 새 줄이 생겼다면 이유와 고칠 계획이 있는가

## 근거

- 동작에 대한 지적은 `파일:줄`을 근거로 단다. 이름만 보고 추정하지 않는다.
- 규칙 위반 지적에는 규칙 문서와 절 이름을 함께 적는다.
- 서로 부딪히는 의견은 두 안을 나란히 적고 고른 이유를 쓴다.
