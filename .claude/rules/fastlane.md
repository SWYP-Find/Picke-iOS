---
paths:
  - "fastlane/**"
  - "Gemfile"
  - "Gemfile.lock"
---

# fastlane 경로 규칙

## Hard

- `QA` 레인은 Stage 빌드를 TestFlight 내부 테스터에게 배포한다. `release` 레인은 App Store 제출이므로 사용자가 명시할 때만 돌린다.
- 레인이 고친 빌드 번호 파일(`Plugins/.../Project+Templete/Extension+String.swift`)은 커밋하지 않는다.
- App Store Connect 키 · 인증서 · 비밀값을 저장소에 넣거나 로그로 출력하지 않는다.

## Soft

- 배포 결과(버전 · 빌드 번호 · 배포 대상)를 PR 또는 작업 보고에 남긴다.
