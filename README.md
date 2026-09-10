# Picke iOS

<div align="center">

**가치관 충돌에서 시작하는 1:1 철학 배틀 플랫폼**

![Platform](https://img.shields.io/badge/Platform-iOS-orange.svg)
![Swift](https://img.shields.io/badge/Swift-6-FA7343.svg?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17.0+-34C759.svg)
![Architecture](https://img.shields.io/badge/Architecture-TCA-purple.svg)
![Tuist](https://img.shields.io/badge/Tuist-4.207.0-blue.svg)

[아키텍처](#아키텍처) · [모듈 그래프](#모듈-그래프) · [빠른 시작](#빠른-시작) · [개발 명령어](#개발-명령어)

</div>

## 프로젝트

Picke는 일상의 가치관 차이를 오늘의 배틀, 1:1 토론, 사전·사후 투표, 리캡 공유로 이어 주는 iOS 앱입니다.

주요 기능:

- Google, Kakao, Apple 기반 소셜 로그인
- 오늘의 배틀, 사전 투표, 1:1 토론, 사후 투표, 리캡 공유
- 홈 피드, 탐색, 검색, 큐레이팅 추천
- 관점 등록, 대댓글, 좋아요, 신고
- 마이페이지, 포인트, 무료 충전, 배틀 기록, 알림 설정
- APNs 푸시 알림과 딥링크 라우팅
- Mixpanel 분석, Google Mobile Ads, Sentry 오류 수집

## 아키텍처

SwiftUI와 The Composable Architecture를 기반으로 한 Clean Architecture 멀티 모듈 프로젝트입니다. Tuist가 프로젝트 생성, 모듈 의존성, 테스트 스킴, 바이너리 캐시 흐름을 관리합니다.

~~~text
Projects/
├── App/                         # 앱 진입점, AppReducer, DI 조립, 리소스
├── Feature/
│   ├── FeatureAssembly/         # 전체 Feature 조립 결과를 앱에 제공
│   ├── FeatureSharedUI/         # Feature 공통 UI
│   ├── Auth/                    # 로그인
│   ├── Home/                    # 홈·출석 모달
│   ├── Battle/                  # 배틀 메인
│   ├── Chat/                    # 채팅·투표·관점·큐레이팅
│   ├── Hifi/                    # 탐색·검색
│   ├── Notification/            # 알림
│   ├── Profile/                 # 마이페이지·설정·리캡
│   ├── Splash/                  # 스플래시·앱 업데이트
│   └── Web/                     # WebView
├── Domain/
│   ├── DomainAssembly/          # 도메인별 라이브 의존성 조립
│   ├── AuthDomain/              # 인증 도메인
│   ├── BattleDomain/            # 배틀 도메인
│   ├── CommentDomain/           # 댓글·대댓글 도메인
│   ├── HomeDomain/              # 홈 도메인
│   ├── NotificationDomain/      # 알림 도메인
│   ├── PerspectiveDomain/       # 관점 도메인
│   ├── ProfileDomain/           # 프로필 도메인
│   ├── SearchDomain/            # 검색 도메인
│   ├── AttendanceDomain/        # 출석 도메인
│   └── AppUpdateDomain/         # 앱 업데이트 도메인
├── Service/
│   ├── ServiceAssembly/         # API·인증·분석·디바이스 서비스 조립
│   ├── API/                     # API 경로 상수
│   ├── APIEndpoint/             # 요청 명세
│   ├── PickeAuth/               # 인증 세션과 토큰 갱신
│   ├── PickeAnalytics/          # 분석 이벤트
│   ├── PickeConfig/             # 앱 환경 설정
│   ├── DeviceService/           # 디바이스·푸시 토큰
│   └── AudioPlayerService/      # 오디오 재생
├── Core/
│   ├── CoreAssembly/            # Core 구현 묶음
│   ├── PickeNetwork/            # Alamofire 기반 네트워크
│   ├── PickeStorage/            # Keychain 저장소
│   ├── PickeCoreLogger/         # 로깅
│   ├── PickeCoreUtility/        # 공통 Swift·TCA 유틸리티
│   ├── PickeCoreUI/             # UI 기반 타입
│   └── PickeThirdParty/         # 외부 패키지 재노출
└── UI/
    ├── PickeDesignKit/          # 디자인 토큰·컴포넌트·리소스
    ├── PickeSharedUI/           # 앱 공통 화면 컴포넌트
    └── PickeAnimation/          # 이미지·애니메이션 리소스
~~~

### 의존성 흐름

~~~mermaid
flowchart TD
    App --> FeatureAssembly
    App --> DomainAssembly
    App --> ServiceAssembly

    FeatureAssembly --> Features[Feature modules]
    Features --> DomainInterfaces["*DomainInterface"]
    Features --> UI[UI modules]

    DomainAssembly --> Domains[Domain modules]
    Domains --> DomainInterfaces
    Domains --> ServiceAssembly

    ServiceAssembly --> Services[Service modules]
    ServiceAssembly --> CoreAssembly
    Services --> CoreAssembly

    CoreAssembly --> Network[PickeNetwork]
    CoreAssembly --> Storage[PickeStorage]
    CoreAssembly --> Logger[PickeCoreLogger]
~~~

설계 원칙:

- App은 FeatureAssembly, DomainAssembly, ServiceAssembly를 통해 앱 전체 의존성을 조립합니다.
- Feature 모듈은 화면, TCA Reducer, Coordinator를 소유하고 외부 IO는 Domain Interface와 UseCase를 통해 호출합니다.
- Domain 모듈은 기능별 Entity, Repository 계약, UseCase 구현을 소유합니다.
- ServiceAssembly는 API, 인증, 분석, 디바이스, 오디오 서비스를 CoreAssembly와 연결합니다.
- CoreAssembly는 Network, Storage, Logger, Utility 등 앱 기반 구현을 묶습니다.
- UI 계층은 디자인 토큰, 공통 컴포넌트, 애니메이션 리소스를 제공합니다.

### 의존성 주입

별도 런타임 DI 컨테이너 대신 Point-Free Dependencies를 사용합니다.

- 각 Domain·Service·Core 모듈은 필요한 `DependencyKey`와 기본값을 선언합니다.
- Assembly 모듈은 live 구현을 `DependencyValues`에 등록합니다.
- Feature는 Repository 구현체를 직접 알지 않고 UseCase 또는 Interface만 사용합니다.
- 테스트·프리뷰 기본값은 Interface 또는 Testing 타깃에서 관리합니다.

## 모듈 그래프

~~~bash
./make graph       # 외부 패키지·Demo를 제외하고 Tests·Testing·Interface를 포함한 모듈 그래프
./make graph:prod  # 외부 패키지·Demo·Tests를 제외한 제품 그래프
~~~

TuistSpider에서 Picke와 주요 조립 모듈을 기준으로 내부 의존성을 확장한 그래프입니다. 외부 의존성은 숨기고, 의존하는 방향을 전체 깊이로 표시했습니다.

<details>
<summary>Picke 전체 모듈</summary>

![Picke 전체 모듈 단계별 그래프](docs/grpah/Picke-grouped-Picke.png)

![Picke 전체 모듈 그래프](docs/grpah/Picke-expanded-Picke.png)

</details>

<details>
<summary>FeatureAssembly</summary>

![FeatureAssembly 모듈 그래프](docs/grpah/Picke-expanded-FeatureAssembly.png)

</details>

<details>
<summary>DomainAssembly</summary>

![DomainAssembly 모듈 그래프](docs/grpah/Picke-expanded-DomainAssembly.png)

</details>

<details>
<summary>ServiceAssembly</summary>

![ServiceAssembly 모듈 그래프](docs/grpah/Picke-expanded-ServiceAssembly.png)

</details>

<details>
<summary>CoreAssembly</summary>

![CoreAssembly 모듈 그래프](docs/grpah/Picke-expanded-CoreAssembly.png)

</details>

<details>
<summary>PickeSharedUI</summary>

![PickeSharedUI 모듈 그래프](docs/grpah/Picke-expanded-PickeSharedUI.png)

</details>

## 기술 스택

| 영역 | 기술 |
|---|---|
| 언어 | Swift 6, Swift Concurrency |
| UI | SwiftUI |
| 상태 관리 | The Composable Architecture 1.26.2 |
| 내비게이션 | TCAFlow 1.1.8 |
| 프로젝트 | Tuist 4.207.0, Mise |
| 의존성 주입 | Point-Free Dependencies |
| 네트워크 | PickeNetwork, Alamofire |
| 로컬 데이터 | SQLiteData |
| 인증 | Sign in with Apple, GoogleSignIn, AppAuth |
| 저장소 | PickeStorage, Keychain |
| 이미지 | SDWebImageSwiftUI, Kingfisher |
| 모니터링 | Firebase Crashlytics, Sentry |
| 분석·광고 | Mixpanel, Google Mobile Ads |
| 테스트 | Swift Testing, XCTest, Tuist |

의존성 버전의 실제 기준은 [Tuist/Package.swift](Tuist/Package.swift)와 [Tuist/Package.resolved](Tuist/Package.resolved)입니다. 보조 패키지 `swift-dependencies`는 Tuist에서 확인된 traits 조건부 의존성 누락 문제를 피하도록 `1.12.0`에 고정했습니다. 이 제한은 소스 빌드와 외부 모듈 캐시 모두에 적용됩니다.

지원 환경:

- iOS 17.0 이상
- Swift 6
- Xcode 26 이상
- iPhone

## 빌드 환경

로컬 확인 기준:

- Xcode 26.5
- Apple Swift 6.3.2
- Tuist 4.207.0

Tuist 버전은 [mise.toml](mise.toml)에 고정되어 있습니다.

~~~bash
mise install
mise exec -- tuist version
~~~

빌드 환경별 xcconfig에 필요한 값을 채웁니다.

~~~xcconfig
BASE_URL              = picke.store
GOOGLE_CLIENT_ID      = YOUR_GOOGLE_WEB_CLIENT_ID
GOOGLE_IOS_CLIENT_ID  = YOUR_GOOGLE_IOS_CLIENT_ID
REVERSED_CLIENT_ID    = YOUR_REVERSED_CLIENT_ID
KAKAO_REST_API_KEY    = YOUR_KAKAO_REST_API_KEY
REWARD_AD_UNIT        = YOUR_REWARD_AD_UNIT
~~~

OAuth redirect URI는 서버 중계 흐름을 기준으로 등록합니다.

| Provider | Redirect URI |
|---|---|
| Google | `https://picke.store/oauth/google` |
| Kakao | `https://picke.store/oauth/kakao` |
| Apple | Native Sign in with Apple |

## Tuist Dashboard와 캐시

이 저장소는 로컬 개발에서만 Tuist Dashboard 프로젝트 `picke2026/picke`를 사용합니다. 일반 generate/project 확인은 Dashboard에 연결해 메트릭을 남기고, 바이너리 캐시 warm은 로컬 저장소만 사용합니다. CI에서는 대시보드 연결과 캐시 준비를 비활성화하며, 별도 CI 캐시 연동 설정은 추가하지 않습니다.

[Tuist.swift](Tuist.swift)의 기준 설정:

- 로컬 generate/project show: `fullHandle = "picke2026/picke"`, 기본 모듈 캐시 프로필 `.onlyExternal`
- 로컬 cache warm: `TUIST_LOCAL_CACHE_ONLY=true` 환경에서만 `fullHandle = nil`, 기본 모듈 캐시 프로필 `.onlyExternal`
- CI: `fullHandle = nil`, 기본 모듈 캐시 프로필 `.none`
- Xcode 컴파일 캐시: 현재 Explicit Modules를 끈 빌드 설정과 호환되지 않아 `enableCaching = false`, `cache.upload = false`로 비활성화
- 인증: `optionalAuthentication = true`로 설정해 로그인되지 않은 환경에서도 generate가 실패하지 않도록 유지

로컬에서 Dashboard 연결과 로컬 바이너리 캐시를 준비하려면 `./make setup`을 실행합니다. 이 명령은 mise 도구 설치 후 Tuist 로그인을 확인하고, 로그인되어 있지 않으면 `tuist auth login`을 실행한 뒤 `Tuist.swift`의 `picke2026/picke` 연결을 `tuist project show`로 확인합니다. 이후 의존성을 설치하고 외부 모듈 바이너리 캐시를 로컬 저장소에 준비한 다음 프로젝트를 생성합니다.

~~~bash
./make setup
~~~

`./make generate`, `./make test`, `./make cache`도 로컬에서는 필요한 Tuist Dashboard 인증과 프로젝트 확인을 먼저 수행합니다. 바이너리 캐시를 쓰지 않을 때는 Tuist 옵션을 그대로 전달합니다.

~~~bash
./make generate --no-binary-cache --no-open
./make test --no-binary-cache
~~~

`./make cache`와 `./make cache:setup`은 기본적으로 `TUIST_LOCAL_CACHE_ONLY=true tuist cache warm --external-only`를 실행해 외부 의존성 중심으로 로컬 캐시를 데웁니다. CI에서는 Dashboard 인증, 프로젝트 확인, 캐시 준비를 건너뛰며, 별도 CI 캐시 연동은 하지 않습니다.

Fastlane이나 CI용 래퍼처럼 캐시가 필요 없는 자동화 경로에서는 `tuist generate --no-binary-cache --no-open` 형태로 실행합니다.

## 빠른 시작

~~~bash
git clone git@github.com:SWYP-Find/Picke-iOS.git
cd Picke-iOS

./make setup
open Picke.xcworkspace
~~~

Xcode에서 `Picke-Stage` 또는 필요한 스킴과 사용할 iPhone 시뮬레이터를 선택해 실행합니다.

`CLAUDE.md`가 필요한 도구는 `AGENTS.md`와 같은 내용을 보도록 심볼릭 링크를 만들 수 있습니다.

~~~bash
ln -s AGENTS.md CLAUDE.md
~~~

## 개발 명령어

~~~bash
./make setup                     # mise 설치, Dashboard 확인, install, 외부 캐시 준비, generate
./make generate                  # Demo 앱을 포함해 Xcode 프로젝트 생성
./make generate --no-open        # Xcode를 열지 않고 프로젝트 생성
./make generate --no-binary-cache --no-open
./make build                     # clean, install, generate
./make install                   # 의존성 설치 후 generate
./make test                      # 전체 테스트
./make test --no-binary-cache    # 로컬 바이너리 캐시 없이 전체 테스트
./make cache                     # 외부 바이너리 캐시 준비
./make cache:setup               # 외부 바이너리 캐시 준비(cache 별칭)
./make format                    # SwiftFormat 적용
./make lint                      # SwiftFormat 검사
./make clean                     # 생성 프로젝트 정리
./make reset                     # DerivedData 정리 후 프로젝트 재생성
~~~

훅 호환용 `make test`는 실제 테스트를 실행하지 않고 스킵 메시지만 출력합니다. 실제 테스트는 `./make test` 또는 `mise exec -- tuist test`를 사용합니다.

새 모듈 생성:

~~~bash
./make feature <이름>
./make core <이름>
./make service <이름>
./make domain <이름>
./make ui <이름>
./make module <레이어> <이름>

# 자동으로 만든 카탈로그 case가 원하는 이름과 다를 때
./make feature <이름> --case <케이스명>
~~~

모듈 생성 명령은 scaffold뿐 아니라 모듈 카탈로그와 해당 레이어 Assembly 의존성도 함께 갱신합니다.

## 배포와 자동화

- Fastlane QA와 release 레인은 빌드 번호를 갱신한 뒤 `tuist generate --no-binary-cache --no-open`로 워크스페이스를 재생성합니다.
- workspace가 없을 때 fallback 경로는 `mise exec -- tuist install` 후 `./make generate --no-binary-cache --no-open`을 실행합니다.
- Bitrise 배포 워크플로는 Fastlane을 통해 TestFlight 또는 App Store 제출을 수행합니다.
- CI에는 Tuist Dashboard 원격 캐시 연동을 추가하지 않습니다.

## 개발 가이드

- [TCA 패턴](docs/agent/tca-patterns.md)
- [SwiftUI 패턴](docs/agent/swiftui-patterns.md)
- [TCAFlow 네비게이션](docs/agent/tcaflow-navigation.md)
- [DI 가이드](docs/agent/dependency-injection.md)
- [Micro Feature 진행 현황](docs/agent/micro-feature-migration-progress.md)
- [도메인/데이터/피처 아키텍처](docs/domain-data-feature-architecture.md)

## 브랜치 전략

- `main`: 프로덕션 배포
- `develop`: 개발 통합
- `feature/*`: 기능 작업
- `fix/*`: 버그 수정

작업 브랜치에서 검증 후 `develop`으로 Pull Request를 올립니다.

## 문의

- Issues: [github.com/SWYP-Find/Picke-iOS/issues](https://github.com/SWYP-Find/Picke-iOS/issues)
- Discussions: [github.com/SWYP-Find/Picke-iOS/discussions](https://github.com/SWYP-Find/Picke-iOS/discussions)
