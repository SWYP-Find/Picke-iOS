# Picke iOS

Picke는 일상의 가치관 차이를 1:1 토론, 투표, 리캡으로 이어 주는 iOS 앱입니다.

![Platform](https://img.shields.io/badge/Platform-iOS-orange.svg)
![Swift](https://img.shields.io/badge/Swift-6-FA7343.svg?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17.0+-34C759.svg)
![Tuist](https://img.shields.io/badge/Tuist-4.x-blue.svg)
![TCA](https://img.shields.io/badge/Architecture-TCA-purple.svg)

## 주요 기능

- Google, Kakao, Apple 기반 소셜 로그인
- 오늘의 배틀, 사전 투표, 1:1 토론, 사후 투표, 리캡 공유
- 홈 피드, 탐색, 검색, 큐레이팅 추천
- 관점 등록, 대댓글, 좋아요, 신고
- 마이페이지, 포인트, 무료 충전, 배틀 기록, 알림 설정
- APNs 푸시 알림과 딥링크 라우팅
- Mixpanel 분석, Google Mobile Ads, Sentry 오류 수집

## 기술 스택

- Swift 6, SwiftUI, iOS 17+
- Tuist 4 기반 멀티 모듈
- The Composable Architecture, TCAFlow
- Dependencies, SQLiteData, Alamofire
- Firebase, Mixpanel, Google Mobile Ads, Sentry

의존성 버전은 고정 표로 관리하지 않습니다. 실제 기준은 [Tuist/Package.swift](Tuist/Package.swift)와 [Tuist/Package.resolved](Tuist/Package.resolved)입니다.

## 프로젝트 구조

```text
Projects/
├── App/             # 앱 진입점, AppReducer, DI 조립, 리소스
├── Feature/         # SwiftUI 화면, TCA Feature, Coordinator
├── Domain/          # Entity, Interface, UseCase, Testing
├── Service/         # API, endpoint, auth, analytics, device/audio service
├── Core/            # network, storage, logger, utility, third party bridge
└── UI/              # design kit, shared UI, animation
```

의존성 방향은 Feature가 Domain Interface를 바라보고, 구현체 조립은 App과 Assembly 계층에서 수행하는 방식입니다. 세부 규칙은 [AGENTS.md](AGENTS.md)와 [docs/agent](docs/agent)를 기준으로 확인합니다.

## 개발 환경

로컬 확인 기준:

- Xcode 26.5
- Apple Swift 6.3.2
- Tuist 4.154.0

Tuist 버전은 [mise.toml](mise.toml)에 고정되어 있습니다. 새 환경에서는 mise를 통해 동일 버전을 맞추는 것을 권장합니다.

```bash
mise install
mise exec -- tuist version
```

## Tuist Dashboard와 캐시

이 저장소는 로컬 개발에서만 Tuist Dashboard 프로젝트 `picke2026/picke`와 원격 바이너리 캐시를 사용합니다. CI에서는 대시보드 연결과 캐시 업로드를 비활성화하며, 별도 CI 연동 설정은 추가하지 않습니다.

[Tuist.swift](Tuist.swift)의 기준 설정:

- 로컬: `fullHandle = "picke2026/picke"`, `enableCaching = true`, 기본 캐시 프로필 `.onlyExternal`
- CI: `fullHandle = nil`, `enableCaching = false`, 기본 캐시 프로필 `.none`
- 캐시 업로드: 로컬에서만 활성화, CI에서는 비활성화
- 인증: `optionalAuthentication = true`로 설정해 로그인되지 않은 환경에서도 generate가 실패하지 않도록 유지

로컬에서 Dashboard와 원격 캐시를 쓰려면 한 번 로그인하고 캐시를 준비합니다.

```bash
tuist auth login
tuist setup cache
tuist cache warm --external-only
tuist generate --no-open
```

`tuist cache warm --external-only`는 외부 의존성 중심으로 캐시를 데우며, 로컬 개발자는 대시보드 원격 캐시에서 다운로드하고 필요한 캐시를 업로드할 수 있습니다.

## 빠른 시작

```bash
git clone git@github.com:SWYP-Find/Picke-iOS.git
cd Picke-iOS
mise install
./make setup
open Picke.xcworkspace
```

`CLAUDE.md`가 필요한 도구는 `AGENTS.md`와 같은 내용을 보도록 심볼릭 링크를 만들 수 있습니다.

```bash
ln -s AGENTS.md CLAUDE.md
```

## 주요 명령어

```bash
./make setup
```

mise 도구 설치, 캐시 설정, 의존성 설치, 프로젝트 생성을 한 번에 실행합니다.

```bash
./make install
```

의존성 설치 후 프로젝트를 생성합니다.

```bash
./make generate
```

Tuist 프로젝트를 생성합니다. 내부적으로 `tuist generate --no-open`을 실행합니다.

```bash
./make build
```

`clean`, `install`, `generate`를 순서대로 실행하는 전체 워크플로우입니다.

```bash
./make test
```

전체 테스트를 실행합니다.

```bash
make test
```

훅 호환용 명령입니다. 실제 테스트를 실행하지 않고 스킵 메시지만 출력합니다.

```bash
mise exec -- tuist test
```

전체 테스트를 실행합니다. 시간이 오래 걸릴 수 있어 CI 또는 수동 검증에서 사용합니다.

```bash
tuist clean
```

Tuist 캐시와 빌드 산출물 문제를 정리할 때 사용합니다.

## 설정

빌드 환경별 xcconfig에 필요한 값을 채웁니다.

```xcconfig
BASE_URL              = picke.store
GOOGLE_CLIENT_ID      = YOUR_GOOGLE_WEB_CLIENT_ID
GOOGLE_IOS_CLIENT_ID  = YOUR_GOOGLE_IOS_CLIENT_ID
REVERSED_CLIENT_ID    = YOUR_REVERSED_CLIENT_ID
KAKAO_REST_API_KEY    = YOUR_KAKAO_REST_API_KEY
REWARD_AD_UNIT        = YOUR_REWARD_AD_UNIT
```

OAuth redirect URI는 서버 중계 흐름을 기준으로 등록합니다.

| Provider | Redirect URI |
| --- | --- |
| Google | `https://picke.store/oauth/google` |
| Kakao | `https://picke.store/oauth/kakao` |
| Apple | Native Sign in with Apple |

## 문서

- [TCA 패턴](docs/agent/tca-patterns.md)
- [SwiftUI 패턴](docs/agent/swiftui-patterns.md)
- [TCAFlow 네비게이션](docs/agent/tcaflow-navigation.md)
- [DI 가이드](docs/agent/dependency-injection.md)
- [Micro Feature 진행 현황](docs/agent/micro-feature-migration-progress.md)
- [도메인/데이터/피처 아키텍처](docs/domain-data-feature-architecture.md)

## 그래프

| Grouped | Expanded |
| --- | --- |
| ![Grouped](docs/graphs/Picke-grouped-Picke.png) | ![Expanded](docs/graphs/Picke-expanded-Picke.png) |

## 브랜치 전략

- `main`: 프로덕션 배포
- `develop`: 개발 통합
- `feature/*`: 기능 작업
- `fix/*`: 버그 수정

작업 브랜치에서 검증 후 `develop`으로 Pull Request를 올립니다.

## 문의

- Issues: [github.com/SWYP-Find/Picke-iOS/issues](https://github.com/SWYP-Find/Picke-iOS/issues)
- Discussions: [github.com/SWYP-Find/Picke-iOS/discussions](https://github.com/SWYP-Find/Picke-iOS/discussions)
