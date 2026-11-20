# Picke iOS

Picke iOS 앱. Swift 6 · SwiftUI · TCA · TCAFlow · Tuist 4 멀티모듈.

이 파일은 색인이다. 세부 규칙은 아래 문서에 있고, 작업에 해당하는 문서만 읽는다.

## 저장소 구조

```
Projects/
  App/        앱 타깃 · 화면 전환 Coordinator(Navigation) · DI 조립 · 앱 단 테스트(PickeTests)
  Feature/    화면 (Reducer · View · Model) — Auth · Battle · Chat · Class · Home · Profile ...
  Domain/     {기능}Domain — Interface(UseCase · Entity) / Sources(구현)
  Service/    API · APIEndpoint · 오디오 · 분석 등 서비스
  Core/       네트워크 · 저장소 · 로거 · 공용 유틸
  UI/         PickeDesignKit(토큰 · 컴포넌트) · PickeSharedUI(팝업 · 공용 뷰)
Tuist/ Plugins/   Tuist 설정 · 모듈 템플릿 (`./make` 명령)
fastlane/         TestFlight(QA) · App Store(release) 배포
```

의존 방향: `App → Feature → Domain Interface ← Domain Sources → Service · Core`. Feature는 UseCase만 쓴다.

## 문서 색인

| 작업 | 먼저 읽을 문서 |
|------|----------------|
| 화면 · View 작성 (필수 SwiftUI 규칙) | `AGENTS.md` "SwiftUI 스타일 가이드" 절 · `docs/agent/swiftui-patterns.md` |
| Reducer · Action · State | `AGENTS.md` "TCA 패턴" 절 · `docs/agent/tca-patterns.md` · 스킬 `pfw-composable-architecture` |
| 화면 전환 (Coordinator) | `docs/agent/tcaflow-navigation.md` |
| 의존성 등록 · UseCase · Repository | `docs/agent/dependency-injection.md` · `AGENTS.md` "UseCase 강제" 절 |
| 팝업 · 토스트 · 모달 | `docs/agent/popup-modal-system.md` |
| Swift 문법 · 오류 처리 · 테스트 | `docs/agent/swift-coding-rules.md` · 스킬 `swift-testing-pro` · `swift-concurrency` |
| 성능 · 빌드 오류 | `docs/agent/ios-performance-optimization.md` |
| Tuist · 모듈 추가 | `docs/agent/development-environment.md` · `.claude/rules/tuist.md` |
| 브랜치 · 커밋 · PR | `docs/agent/git-workflow.md` |
| 코드 리뷰 (심각도 · 제외 · 항상 확인) | `REVIEW.md` |
| 에이전트 · 훅 · 검증 게이트 | `docs/agent/harness.md` |
| Android 동작과 맞추기 | 작업별 대조 기록 `docs/class-android-ios-parity-*.md` 형식을 따른다 |

경로별 규칙은 `.claude/rules/`에 있다. 해당 경로의 파일을 다룰 때 자동으로 적용된다.

## 반드시 지킬 규칙 (Hard)

1. `main`, `develop`, `release`에 직접 커밋하거나 푸시하지 않는다. 작업 브랜치(`feature/` · `fix/` · `chore/` 등)에서 `develop`으로 PR을 연다. 훅이 막는다.
2. 커밋 제목은 한국어 한 줄, 50자 이하, 마침표로 끝내지 않는다. `Co-Authored-By: Claude` 줄을 넣지 않는다. 훅이 검사한다.
3. 코드를 바꿨으면 `.claude/scripts/verify`가 통과해야 커밋할 수 있다. 통과 뒤 코드를 고치면 다시 돌린다. 훅이 막는다.
4. Feature는 Repository · Domain 구현 · 네트워크 모듈에 직접 의존하지 않는다. `{기능}DomainInterface`의 UseCase를 쓴다. verify가 검사한다.
5. `AGENTS.md`의 "(필수)" SwiftUI · TCA 규칙을 지킨다. Codex PR 리뷰가 이 기준으로 지적한다.
6. `.xcodeproj` · `.xcworkspace`는 Tuist가 만든다. 직접 고치거나 커밋하지 않는다. 새 파일을 넣으면 `./make generate --no-open`.
7. fastlane이 고친 빌드 번호 파일(`Plugins/.../Project+Templete/Extension+String.swift`)은 커밋하지 않는다. App Store `release` 레인은 사용자가 명시할 때만 돌린다.
8. 검증하지 않은 결과를 완료로 보고하지 않는다. 실행한 명령과 결과를 PR 본문에 적는다.
9. 한 커밋은 30파일 이하로 나눈다. 30을 넘으면 모듈 · 변경 종류로 끊는다.

## 명령

```bash
./make generate --no-open      # 프로젝트 생성 (새 파일 · 모듈 추가 후)
./make feature <이름>          # 모듈 scaffold (core · domain · service · ui 동일)
./make test                    # tuist test 전체
.claude/scripts/verify         # 바뀐 경로에 맞는 검증 (커밋 전 필수)
.claude/scripts/verify --dry-run   # 돌릴 단계만 보기
.claude/scripts/harness-report # 하네스 문서 · 규칙 사용 리포트
bundle exec fastlane QA        # TestFlight(Stage) 배포
```

## 문서 갱신

규칙을 바꾸면 같은 PR에서 해당 문서와 훅을 고친다. 이 파일은 200줄 아래로 유지한다.
