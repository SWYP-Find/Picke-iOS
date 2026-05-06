# Picke iOS Architecture Guide

## 📱 프로젝트 개요

- **프로젝트명**: Picke
- **스택**: Swift 6, SwiftUI, TCA 1.25, Tuist 4
- **아키텍처**: TCA + Clean Architecture 멀티모듈
- **배포 타겟**: iOS 17.0+, iPhone 전용
- **네비게이션**: TCAFlow
- **의존성 주입**: WeaveDI 3.4.1

## 🏗️ 아키텍처 및 모듈 구조

### Clean Architecture 계층

```
Projects/
├── App/                  # 앱 타겟 (진입점, DI 조립)
│   ├── Sources/         # AppReducer, App Entry Point
│   ├── Resources/       # Assets, Info.plist
│   └── Tests/           # 앱 단 통합 테스트
├── Presentation/         # 화면 + ViewModel (TCA Feature)
│   └── Presentation/    # Feature Reducer + SwiftUI View
├── Domain/
│   ├── Entity/           # 도메인 엔티티 + Entity Protocol
│   ├── UseCase/          # 비즈니스 로직 구현
│   ├── DomainInterface/  # Repository / UseCase 인터페이스
│   └── DataInterface/    # Data 계층 인터페이스
├── Data/
│   ├── Model/            # DTO, API Response → Entity 변환
│   ├── Repository/       # Repository 구현체
│   ├── API/              # REST API Endpoint
│   └── Service/          # 데이터 처리 서비스
├── Network/
│   ├── Networking/       # HTTP 클라이언트 설정
│   ├── Foundations/      # 네트워크 기반 유틸리티 (Token, Header)
│   └── ThirdPartys/      # AsyncMoya, WeaveDI 등
└── Shared/
    ├── DesignSystem/     # 공통 UI 컴포넌트, 폰트, 색상
    ├── Shared/           # 공통 공유 모듈
    └── Utill/            # 날짜, 문자열, 로깅 유틸리티
```

**의존성 방향**: `Presentation → Domain ← Data`, `Network`는 `Data`에서만 참조

### 주요 의존성

```swift
// Core Architecture
ComposableArchitecture: 1.25.5       // TCA
Dependencies:           1.10.0       // TCA 의존성 관리
TCAFlow:                1.1.2        // @FlowCoordinator 기반 네비게이션
WeaveDI:                3.4.1        // 의존성 주입
IdentifiedCollections:  1.1.0+

// Networking
AsyncMoya:              1.1.8        // 비동기 네트워크 (Moya 래퍼)
Moya:                   15.0.3
Alamofire:              5.11.1
ReactiveSwift:          6.7.0
RxSwift:                6.10.2

// Authentication
AppAuth-iOS:            2.0.0        // OAuth 2.0
GoogleSignIn-iOS:       9.1.0        // Google 소셜 로그인

// Firebase
firebase-ios-sdk:       12.12.0      // Crashlytics / Messaging

// Analytics / Ads
GoogleMobileAds:        13.3.0       // AdMob 광고
Mixpanel:               5.2.0        // 제품 분석
MixpanelSessionReplay:  1.4.0        // 세션 리플레이

// UI / Utility
SDWebImageSwiftUI:      3.1.4        // 이미지 비동기 로딩
Kingfisher:             8.2.0        // 이미지 로딩
LogMacro:               1.1.1        // 로깅 매크로
```

## 📚 세부 가이드 문서

프로젝트의 상세 가이드는 `docs/agent/` 폴더에서 관리합니다.

### 🔄 TCA 패턴 가이드 (`docs/agent/tca-patterns.md`)
- TCA 기본 구조 및 규칙
- Extension 패턴 활용법
- Action 처리 메서드 분리
- State Computed Properties
- Coordinator Extension 패턴

### 🎨 SwiftUI 스타일 가이드 (`docs/agent/swiftui-patterns.md`)
- SwiftUI 코드 구조화
- View Extension 패턴
- Computed Properties + @ViewBuilder 조합
- 조건부 렌더링 및 Skeleton 패턴

### 📏 Swift 코딩 규칙 (`docs/agent/swift-coding-rules.md`)
- Swift 스타일 가이드
- 에러 처리 패턴
- TCA 에러 처리 규칙
- 테스트 패턴

### 🚨 팝업 & 모달 시스템 (`docs/agent/popup-modal-system.md`)
- CustomAlert (TCA 기반 커스텀 알림)
- Toast 시스템 (전역 메시지)
- CustomModal (드래그 지원 모달)
- TCA Presentation 패턴 규칙

### 🔄 의존성 주입 (`docs/agent/dependency-injection.md`)
- WeaveDI 3.4.1 패턴
- AppDIManager 구조
- TCA Dependencies 통합
- Interface 기반 등록 규칙

### 🚀 iOS 성능 최적화 (`docs/agent/ios-performance-optimization.md`)
- 성능 최적화 통합 시스템
- 서브에이전트 호출 규칙
- TCA/SwiftUI 성능 문제 해결
- 빌드 오류 해결 프로세스

### 🎯 Git 워크플로우 (`docs/agent/git-workflow.md`)
- 브랜치 전략
- 커밋 메시지 컨벤션
- Pull Request 규칙
- 코드 리뷰 가이드라인

### ✅ 커밋 메시지 언어 규칙
- 에이전트가 작성하는 **모든 git commit 메시지는 한국어로 작성**
- 커밋 제목/본문 모두 한글 기준으로 작성
- 영문 타입 prefix(`feat`, `fix`, `refactor`, `test`, `chore`)는 사용 가능하지만, **설명 문구는 반드시 한국어**
- 커밋 제목에는 관련 GitHub 이슈 번호를 포함해 `chore: #1 SPM 의존성 확장`처럼 이슈와 바로 매칭되게 작성
- 커밋 본문은 장황한 문장보다 `- 변경 요약` bullet 형식을 우선 사용하고, 변경 파일/모듈별 핵심 의도와 후속 주의사항을 짧게 정리
- 별도 요청이 없는 한 영어 커밋 메시지는 사용하지 않음
- 커밋 메시지에 `Co-Authored-By: Claude ...` 등의 자동 서명 라인을 절대 추가하지 않음
- OMX 훅 검증을 위해 커밋 명령에는 `Co-authored-by: OmX <omx@oh-my-codex.dev>` trailer를 포함하되, 최종 커밋 메시지에서는 제거

### 🧭 TCAFlow 네비게이션 (`docs/agent/tcaflow-navigation.md`)
- @FlowCoordinator 패턴
- 기본 네비게이션 동작 (Push, Present, Dismiss)
- 화면 간 통신 패턴
- 딥 링크 처리

### 🔧 개발 환경 설정 (`docs/agent/development-environment.md`)
- TuistTool / Make 명령어
- Xcode 빌드 설정 (Dev, Stage, Prod, Release)
- Tuist 사용 규칙
- 테스트 패턴

## ⚙️ 빌드 & 실행

### 워크스페이스
- 메인: `Picke.xcworkspace`
- Tuist 생성 결과: `Projects/App/Picke.xcodeproj`

### 자주 쓰는 명령어
```bash
# 의존성 설치 + 프로젝트 생성 (clean → install → generate)
./tuisttool build

# 의존성만 재설치
./tuisttool install

# 캐시 전체 클린 후 재생성
./tuisttool reset

# 테스트 실행
tuist test

# 의존성 그래프 확인
tuist graph --format pdf --path ./graph.pdf
```

### 빌드 환경 (`Config/`)
- `Dev.xcconfig` — 개발 환경
- `Stage.xcconfig` — 스테이징
- `Prod.xcconfig` — 프로덕션
- `Release.xcconfig` — 릴리즈 빌드 공통
- `Shared.xcconfig` — 모든 환경 공통 설정

## 📊 지원 스킬 목록

### TDD 자동화 스킬
- `@test-auto-pr-agent` — **Swift Testing 기반 완전 자동 테스트 생성**
  - 도메인별 테스트 코드 자동 생성 (Entity / UseCase / Repository)
  - **Swift Testing** 프레임워크 사용 (XCTest 대신)
  - **TCA TestStore**, **WeaveDI Mock** 자동 설정
  - 테스트 실행 → 실패 시 자동 수정 → 성공까지 반복

### 성능 최적화 스킬
- `@ios-performance-optimizer` — PFW 철학 통합 자동화 시스템 (v4.0)
- `@ios-performance-pfw` — Point-Free Workshop 전문
- `@swiftui-uikit-interop` — SwiftUI ↔ UIKit 상호 운용성 전문
- `@swift-concurrency` — Swift 6 Concurrency 및 async/await 전문

### 자동 호출 키워드
다음 키워드 언급 시 **자동으로 성능 최적화 스킬 호출**:
- `ifCaseLet`, `TCA`, `Effect`, `메모리 누수`, `성능`, `최적화`
- `SwiftUI`, `렌더링`, `빌드 시간`, `TCAFlow`, `WeaveDI`
- `Cannot infer`, `Extensions must not`, `Type annotation missing`
- `빌드 오류`, `컴파일 에러`, `SourceKit error`

---

이 문서는 Picke iOS 프로젝트의 **아키텍처 가이드라인**입니다.
새로운 기능 개발이나 코드 리뷰 시 이 가이드와 세부 문서들을 참고하여 일관성 있는 코드를 작성해주세요.
