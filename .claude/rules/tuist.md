---
paths:
  - "Tuist/**"
  - "Plugins/**"
  - "**/Project.swift"
  - "Tuist.swift"
  - "TuistTool.swift"
  - "WorkSpace.swift"
---

# Tuist 경로 규칙

상세 문서: `docs/agent/development-environment.md`

## Hard

- 새 모듈은 `./make feature|core|domain|service|ui <이름>`으로 만든다. 카탈로그 case와 엄브렐러 의존성이 함께 등록된다.
- 매니페스트를 고친 뒤 `./make generate --no-open`으로 생성이 되는지 확인한다. verify가 generate와 앱 빌드를 돌린다.
- `Plugins/.../Project+Templete/Extension+String.swift`의 빌드 번호 변경은 fastlane이 만든 것이다. 커밋하지 않는다.

## Soft

- 외부 패키지 버전을 바꾸면 PR 본문에 이유와 확인한 빌드를 적는다.
