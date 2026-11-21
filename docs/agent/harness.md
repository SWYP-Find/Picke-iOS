# 에이전트 하네스

하네스는 에이전트가 일하는 환경 전체다. 규칙 파일, 경로별 규칙, 훅, 검증 스크립트로 이루어진다.

참고: 카카오페이 기술 블로그 "AI Agent, 넌 누구냐 1 · 2", 카카오모빌리티 "카카오 T 주차 하네스 엔지니어링 적용기".

- 프롬프트 지시는 확률이고, 실행되는 검사는 보장이다. 같은 실수가 나오면 문서를 고치기보다 그 실수를 검사로 막는다.
- 하네스는 세 축으로 관리한다. **Context**(무엇을 읽게 할지) · **Control**(무엇을 막고 확인할지) · **Observability**(무엇이 쓰이는지 보고 정리).
- 규칙 파일은 짧게(200줄 미만) 두고, 경로별로 나눠 필요한 파일을 다룰 때만 읽게 한다.
- 규칙은 반드시 지킬 것(Hard)과 권장(Soft)으로 나눈다. Soft는 기존 코드가 다르면 기존 코드를 따른다.

## 구성

| 종류             | 위치                                        | 역할                                                                | 언제 읽히나                   |
| ---------------- | ------------------------------------------- | ------------------------------------------------------------------- | ----------------------------- |
| 색인 · Hard 규칙 | `CLAUDE.md`                                 | 구조 · 문서 색인 · Hard 규칙 · 명령                                 | Claude 세션 시작 시           |
| 상세 코드 규칙   | `AGENTS.md`                                 | SwiftUI · TCA 필수 규칙 원본. Codex(PR 리뷰 포함)가 자동으로 읽는다 | Codex 세션 · 작업에 맞는 절   |
| 상세 문서        | `docs/agent/*.md`                           | 영역별 규칙과 예시                                                  | 작업에 맞는 문서를 골라 읽음  |
| 리뷰 기준        | `REVIEW.md`                                 | 심각도 · 제외 · 항상 확인                                           | 리뷰할 때                     |
| 경로별 규칙      | `.claude/rules/*.md`                        | `paths`에 맞는 파일을 다룰 때만 적용                                | 자동 (Claude) · 직접 (Codex)  |
| 훅               | `.claude/hooks/*` + `.claude/settings.json` | 규칙을 실행으로 강제 · 사용 기록                                    | 도구 실행 전후 · 응답 종료 시 |
| 스크립트         | `.claude/scripts/*`                         | 검증 · 경계 검사 · 자체 검사 · 사용 리포트                          | 직접 실행                     |
| 로컬 상태        | `.claude/state/` (git 제외)                 | 검증 기록 · 사용 기록 · 로그 · 검증 전용 DerivedData                | 훅 · 스크립트가 읽고 씀       |

`CLAUDE.md`는 짧은 색인이고 `AGENTS.md`는 긴 규칙 원본이다. Codex PR 리뷰가 `AGENTS.md`의 필수 규칙으로 지적하므로 본문을 옮기지 않는다.

## 경로별 규칙

| 파일                        | 적용 경로                                                                      |
| --------------------------- | ------------------------------------------------------------------------------ |
| `.claude/rules/ios.md`      | `Projects/**`                                                                  |
| `.claude/rules/tuist.md`    | `Tuist/**`, `Plugins/**`, `**/Project.swift`, `Tuist.swift`, `TuistTool.swift` |
| `.claude/rules/fastlane.md` | `fastlane/**`                                                                  |

## 훅

| 이벤트                       | 스크립트                                           | 검사 내용                                                                                                                                                                                                       |
| ---------------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PreToolUse` (Bash)          | `check-git-rules.sh` → `check_git_rules.py`        | 보호 브랜치 커밋 · 푸시 · 삭제 금지, 브랜치 이름, 커밋 제목(한국어 · 50자 · 마침표), `.DS_Store`, `Co-Authored-By: Claude`, 게이트 우회(`--no-verify` · `-n` · `core.hooksPath` 변경), **검증 안 된 코드 커밋** |
| `PostToolUse` (Read · Skill) | `usage_log.py`                                     | 하네스 문서 · 규칙 · 스킬 사용을 `.claude/state/usage.jsonl`에 기록                                                                                                                                             |
| git `pre-commit`             | 심 → `.githooks/pre-commit` → `pre_commit_gate.py` | 커밋될 index의 코드가 verify 통과 시점과 다르면 커밋 금지                                                                                                                                                       |
| `Stop`                       | `stop_guard.py`                                    | 검증 안 된 코드 변경이 있으면 응답 종료를 한 번 막고 verify를 안내                                                                                                                                              |

공용 판정(코드 경로 · 지문 · 검증 기록 · 훅 설치)은 `harness_state.py` 하나에 둔다.

- 이 저장소의 `core.hooksPath`는 `.git/hooks`이고 거기에 Git LFS 훅과 `commit-msg` 정리 훅이 있다. **hooksPath를 바꾸지 않는다.** verify와 커밋 게이트가 그 폴더에 표식 줄(`# picke-harness pre-commit`)이 있는 `pre-commit` 심을 만든다.
- 게이트를 부르지 않는 다른 `pre-commit`이 이미 있으면 덮어쓰지 않고 실패한다(verify exit 1, 커밋 게이트 exit 2). 표식 줄만으로는 통과하지 않는다. 기존 훅에 표식 줄과 `"$(git rev-parse --show-toplevel)/.githooks/pre-commit" "$@" || exit 1` 줄(줄 전체 그대로)을 넣으면 풀린다.
- 커밋 제목은 `-m` 리터럴 · `-F` 파일 · heredoc일 때 검사한다. `-m "$MSG"` · `-m "$(cat 파일)"`처럼 셸이 바꾸는 제목은 미리 알 수 없어 막는다(작은따옴표 안 · `\$`의 `$`는 글자 그대로라 통과). git 별칭 정의(`-c alias.x=…` · `git config alias.x …`)도 우회 옵션을 숨길 수 있어 막는다.
- `.githooks/pre-commit`은 **HEAD에 커밋된** 게이트를 꺼내 실행한다. 게이트 자체를 바꾸는 커밋도 이전 게이트로 검사된다.
- PreToolUse 훅은 명령 실행 **전** 작업 트리를 본다. 같은 명령 안에서 고친 뒤 `commit -a` 하면 놓치므로 실제 차단은 `pre-commit`이 커밋 직전 index로 한다. 사람이 터미널에서 커밋해도 같은 검사를 받는다.
- 훅은 빨라야 한다. git commit · push가 아니면 bash 문자열 비교만 하고 끝낸다. 지문 계산은 코드 파일 전체를 새 index로 해시한다(약 1.5초). 실제 index를 복사하면 같은 크기로 빠르게 고친 파일을 stat 캐시로 놓친다.
- 위반하면 `exit 2`와 stderr 메시지로 명령을 막는다. 에이전트는 메시지를 보고 고친 뒤 다시 실행한다.
- 로컬 게이트는 실수 방지용이다. 심이나 `.githooks/pre-commit`을 바꾸는 우회는 PR 리뷰(`REVIEW.md`)가 막는다.

직접 검사:

```bash
bash .claude/hooks/check-git-rules.sh --check-message "클래스 수정 화면 추가"
bash .claude/hooks/check-git-rules.sh --check-branch "feature/class-edit-20261121"
.claude/scripts/harness-check      # 훅 · 게이트 자체 시험
```

## 검증 게이트 (Control)

```bash
.claude/scripts/verify            # develop 이후 바뀐 코드에 맞는 단계만
.claude/scripts/verify --dry-run  # 돌릴 단계만 보기
.claude/scripts/verify --all      # 모든 모듈 테스트 + 앱 빌드
```

| 바뀐 경로                                                                                                       | 단계                       | 명령                                                                               |
| --------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------------------------------------------------------------------------- |
| `.claude/hooks` · `.claude/scripts` · `.githooks` · `.claude/settings.json` · `.claude/known-test-failures.txt` | harness                    | `.claude/scripts/harness-check`                                                    |
| `Projects` · `Tuist` · `Plugins` · `Entitlements` · Tuist 루트 파일 · `make` · `mise.toml` · `.swiftformat`     | boundaries                 | `.claude/scripts/check-boundaries` (Feature의 UseCase 경계 · `try!` · 생성물 추적) |
| 위와 같음                                                                                                       | generate                   | `./make generate --no-open`                                                        |
| `Projects/{레이어}/{모듈}/**`                                                                                   | test:{모듈} · build:{모듈} | Tests 폴더가 있으면 `xcodebuild test`, 없으면 `build` (스킴 = 모듈 이름)           |
| `Projects/App/**`                                                                                               | test:App                   | `Picke-Stage`(Stage) `-only-testing:PickeTests`, 알려진 실패는 `-skip-testing`     |
| App이 안 바뀌었을 때                                                                                            | build:App                  | `Picke-Stage` 빌드로 의존 모듈이 깨졌는지 확인                                     |

- `.md`만 바뀌면 검증하지 않는다. fastlane 빌드 번호 파일도 검증 대상이 아니다.
- xcodebuild는 `.claude/state/DerivedData`와 `COMPILATION_CACHE_ENABLE_CACHING=NO`를 쓴다. 기본 DerivedData에서 Sentry 컴파일 · 컴파일 캐시 연결 오류가 난 적이 있다. 첫 실행은 전체 빌드라 오래 걸린다.
- 시뮬레이터는 부팅된 iPhone을 먼저 쓴다. `PICKE_VERIFY_DESTINATION="platform=iOS Simulator,id=..."`로 바꿀 수 있다.
- 통과하면 작업 트리 지문과 파일별 blob 목록을 `.claude/state/verify.json`에 남긴다. 커밋을 나눠도 각 파일 내용이 검증한 그대로면 다시 돌리지 않는다. 삭제한 파일은 `deleted`로 기록해 비교한다.
- 각 단계 출력은 `.claude/state/verify/{단계}.log`에 남긴다.

### 알려진 실패

`.claude/known-test-failures.txt`에 develop에서 이미 실패하는 테스트를 적는다. verify는 이 줄들을 `-skip-testing`으로 빼고 매번 "알려진 실패 N건 제외"를 출력한다. 고치면 줄을 지운다. 새 줄을 넣을 때는 이유와 날짜를 주석으로 단다.

### 재시도 한도

| 단계                               | 최대          | 넘으면                                                                 |
| ---------------------------------- | ------------- | ---------------------------------------------------------------------- |
| 빌드 · 테스트 (verify의 같은 단계) | 연속 2번 실패 | 멈추고 시도한 내용 · 실패 원인을 사용자에게 보고, 승인 후 세 번째 시도 |
| 리뷰 (Codex 교차 검토)             | 3번           | 남은 지적을 PR 본문에 적고 사용자에게 판단을 맡긴다                    |

## 관측과 정리 (Observability)

```bash
.claude/scripts/harness-report            # 최근 30일
.claude/scripts/harness-report --days 90
```

- 문서 · 규칙 · 스킬별 읽은 횟수와 마지막 사용일, 기간 안에 한 번도 쓰이지 않은 항목을 보여준다.
- 기록에는 경로와 스킬 이름만 남긴다. 사용자 입력은 남기지 않는다.
- 한 달에 한 번 리포트를 보고, 오래 안 읽힌 문서는 합치거나 지우고, 동작하지 않는 규칙은 고친다.

## 겪은 문제

- 검증 명령 뒤 `| tail`은 종료 코드를 가린다. 검증은 로그 파일로 남기고 종료 코드를 직접 본다.
- `git stash`는 같은 작업 트리를 쓰는 다른 세션의 변경을 날릴 수 있다. 쓰지 않는다. 지문 계산도 임시 index로 한다.
- `swiftformat --lint .`는 기존 코드에서 4천여 건 실패한다. 게이트에 넣지 않았다. 일괄 포맷 PR을 따로 낸 뒤 넣는다.
- Codex를 `codex exec`로 부를 때 stdin을 닫지 않으면 입력을 기다리며 멈춘다. `< /dev/null`을 붙인다.

## Claude와 Codex

- Codex에는 Claude 훅이 걸리지 않는다. Codex는 커밋 전에 위 직접 검사와 `.claude/scripts/verify`를 실행한다. git `pre-commit` 게이트는 둘 다에 걸린다.
- 교차 검토: 한쪽이 계획하거나 구현하면 다른 쪽이 같은 문서를 기준으로 검토한다.

## 하네스 관리

- 규칙을 바꾸면 같은 PR에서 문서와 훅을 함께 고친다.
- 에이전트가 같은 실수를 두 번 하면 문서에 적고, 세 번째부터는 검사로 만든다.
- 새 경계 규칙은 develop에서 위반이 0건일 때만 `check-boundaries`에 넣는다.
- 모델이 나아지면 필요 없어진 규칙과 훅을 지운다. 검증과 보호 브랜치 규칙은 남긴다.
