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

#### 📐 View 분할 — extension + private func 패턴 (필수)

View `body` 는 최상위 레이아웃 (`ZStack` / `VStack`) 만 두고, 모든 하위 영역은 같은 파일의 `extension View {}` 안에 `private func sectionName() -> some View` (또는 `private var sectionName: some View`) 로 분리합니다.

`LoginView` / `OnBoardingView` 가 정착된 레퍼런스입니다.

```swift
// ✅ 올바른 패턴 — LoginView 와 동일하게 extension 분리
public struct OnBoardingView: View {
  @Bindable var store: StoreOf<OnBoardingFeature>

  public var body: some View {
    ZStack {
      Color.bgSubtle.edgesIgnoringSafeArea(.all)
      VStack(spacing: 0) {
        topSection()
          .frame(maxHeight: .infinity)
        bottomSection()
          .padding(.horizontal, 16)
          .padding(.bottom, 40)
      }
    }
  }
}

extension OnBoardingView {
  private func topSection() -> some View {
    TabView(selection: $store.currentIndex) { /* ... */ }
  }

  private func bottomSection() -> some View {
    VStack(spacing: 24) {
      OnBoardingPageIndicator(/* ... */)
      CustomButton(/* ... */)
    }
  }
}

// ❌ 금지 — body 안에 모든 레이아웃을 inline 으로 작성하지 말 것
public var body: some View {
  VStack {
    TabView { /* ... */ }
    VStack { /* indicator + button */ }
  }
}
```

규칙:
- `body` 는 호출자만, 실제 레이아웃은 `extension` 안으로
- 메서드 이름은 의도가 드러나는 명사형 (`topSection`, `bottomSection`, `loginSNSButtonText`, `logoView`)
- 한 메서드 안에서 다시 큰 블록이 생기면 더 작게 쪼개기 (재귀 적용)
- 공통 컴포넌트는 별도 파일 (`Components/*.swift`) 로 추출

#### 🔤 폰트 — `.font(.system(...))` 금지, Pretendard 토큰 사용

```swift
// ✅ 디자인 시스템 토큰이 있는 경우 (16/14/12 등)
Text("시작하기")
  .pretendardCustomFont(textStyle: .headingMedium)

// ✅ 토큰에 없는 임의 크기 (24, 15 등 Figma 스펙 그대로)
Text(page.title)
  .pretendardFont(family: .SemiBold, size: 24)

Text(page.subtitle)
  .pretendardFont(family: .Medium, size: 15)

// ❌ 금지 — 시스템 폰트 직접 사용
.font(.system(size: 24, weight: .semibold))
```

#### 🎨 컬러 — `.foregroundStyle(.neutral900)` 단축형 사용

```swift
// ✅ 컨텍스트 추론 가능한 위치는 점 단축형
Text(...)
  .foregroundStyle(.neutral900)
Color.bgSubtle.edgesIgnoringSafeArea(.all)

// ❌ 금지 — 매번 Color 타입 명시
.foregroundStyle(Color.neutral900)
```

`SwiftUI.Color` 의 정적 멤버로 디자인 토큰 (`neutral50` … `neutral900`, `primary50` … `primary900`, `secondary50` …, `bgSubtle`) 이 등록되어 있어 `.foregroundStyle / .fill / .background / .tint` 등에서 모두 점 단축형 사용 가능.

#### 🖼 이미지 — `Image(asset: .xxx)` + 데이터 모델은 `ImageAsset` 타입

```swift
// ✅ 데이터 모델이 String 이 아닌 ImageAsset 을 보유
public struct Page: Equatable, Identifiable {
  public let imageAsset: ImageAsset
}

// View 에서는 단축 init 만 사용
Image(asset: page.imageAsset)
  .resizable()
  .scaledToFit()

// ❌ 금지 — rawValue 문자열 / bundle 명시
Image(page.imageName, bundle: .module)
Image(ImageAsset.onboarding1.rawValue)
```

이미지 케이스가 추가되면 반드시:
1. `Projects/Shared/DesignSystem/Resources/ImageAssets.xcassets/<카테고리>/<name>.imageset/` 폴더 + `Contents.json` 추가
2. `ImageAsset` enum 에 `case <name>` 추가 (raw value = imageset 폴더명과 동일)
3. `tuist generate` 로 리소스 재인덱싱

#### 🧲 Store 보유 — `@Bindable private var store: StoreOf<Feature>` 고정

TCA View 가 `store` 를 들고 있을 때는 **항상 `@Bindable`** 로 선언한다. 단순 표시뿐이라도 future-proof 하기 위해 동일.

```swift
// ✅ 올바른 패턴
public struct OnBoardingView: View {
  @Bindable var store: StoreOf<OnBoardingFeature>
}

public struct MainTabView: View {
  @Bindable private var store: StoreOf<MainTabCoordinator>
}

// ❌ 금지 — 그냥 let / var
public struct TabFeatureView: View {
  let store: StoreOf<TabFeature>          // ← @Bindable 누락
  var store: StoreOf<HomeFeature>          // ← 동일하게 누락
}
```

근거:
- `$store.binding` 형태가 필요한 시점이 거의 반드시 옴 (TabView selection, TextField, NavigationDestination 등)
- `@Bindable` 은 read-only 사용 시에도 비용이 없고, 후에 binding 이 추가될 때 시그니처 변경 없이 받음
- LoginView / OnBoardingView / MainTabView / AuthCoordinatorView 모두 이 규칙 따름

가시성:
- 외부에서 store 를 주입받는 표면은 `public` 또는 그대로 두고,
- 그 외 내부에서만 쓸 store 는 `private` 으로 가린다 (`@Bindable private var store`)

#### 🧮 텍스트 / 라벨 — `body` 안에 인라인 표현 금지, State computed 로

표시용 파생값은 View 가 아니라 `State` 의 computed property 로 정의해서 View 에서는 그대로 꺼내기만 한다.

```swift
// ✅ State 가 자기 자신을 설명
@ObservableState
public struct State: Equatable {
  public var currentIndex: Int
  public var isLastPage: Bool { currentIndex >= pageCount - 1 }
  public var primaryButtonTitle: String { isLastPage ? "시작하기" : "다음" }
}

// View
CustomButton(
  title: store.primaryButtonTitle,
  ...
)

// ❌ 금지 — View 안에서 store 상태를 다시 가공
private var primaryButtonTitle: String {
  store.isLastPage ? "시작하기" : "다음"
}
```

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

## 🎨 디자인 시스템 & 토큰 워크플로우

### 디자인 토큰 코드젠 (`Tools/TokenGenerator.swift`)

Tokens Studio for Figma 가 export 한 `Mode 1.tokens.json`을 Swift 토큰으로 변환합니다.

**단일 소스**
- 토큰 JSON 은 `SWYP-Find/design-tokens` 레포(public)가 단일 소스
- Picke-iOS 의 `Projects/Shared/DesignSystem/Resources/Mode 1.tokens.json` 은 워크플로우 실행 시에만 다운로드되는 임시 파일이며 git 에 추적되지 않음 (`.gitignore` 처리)

**자동 생성 출력 (⚠️ 직접 수정 금지 — 헤더에 AUTO-GENERATED 마크)**
- `Sources/Color/ShapeStyle+.swift` — 색 토큰 (`.primary500`, `.bgDefault`, `.borderError` 등)
- `Sources/Extension/CGFloat/CGFloat+Radius+.swift` — radius (`.none` / `.default` / `.full`)
- `Sources/Extension/CGFloat/CGFloat+Spacing+.swift` — spacing (`.s0` ~ `.s96`)
- `Sources/UI/Token/ComponentToken.swift` — 컴포넌트 토큰 (`ComponentToken.Button.Primary.Background.default` 등)

**디자이너 핸드오프 흐름 (자동)**
1. 디자이너가 Tokens Studio → `Mode 1.tokens.json` export
2. `SWYP-Find/design-tokens` 의 `main` 브랜치에 push
3. (자동) `notify-ios.yml` → `repository_dispatch(design-tokens-updated)` 발사
4. (자동) Picke-iOS `sync-design-tokens.yml` 실행 → raw URL 로 JSON 다운로드 → `swift Tools/TokenGenerator.swift` → 4개 출력 파일을 `develop` 에 직접 commit + push

수동 트리거가 필요할 때:
```bash
gh workflow run sync-design-tokens.yml --repo SWYP-Find/Picke-iOS
```

**Component 토큰 해석 우선순위** (TokenGenerator 내부)
1. `"{Colors.brand.primary.500}"` 같은 string alias → `.primary500`
2. inline hex + `$extensions.com.figma.aliasData.targetVariableName` → 해당 변수명이 우리 토큰셋에 있으면 그쪽으로
3. inline hex가 brand/semantic 변수의 hex와 일치하면 그 변수로
4. 위 셋 다 실패 시 `.init(hex: "...")` inline

### DesignSystem 폴더 구조

```
Projects/Shared/DesignSystem/Sources/
├── Color/                     # 색 토큰 (auto)
├── CustomFont/                # Pretendard 폰트 정의
├── Image/                     # ImageAsset
├── Extension/
│   ├── CGFloat/               # radius / spacing (auto)
│   ├── Color/                 # Color/UIColor hex 초기화 등
│   ├── Image/
│   └── ScreenSize/
└── UI/
    ├── Button/                # CTA 버튼 컴포넌트
    ├── Navigaion/             # UINavigationController gesture 확장
    └── Token/                 # 컴포넌트 토큰 (auto)
```

### UI 컴포넌트 작성 규칙

- **색·radius는 `ComponentToken.*` 또는 brand/semantic 토큰 참조**. hex 리터럴(`.init(hex: "...")`) 직접 사용 금지
- **CTA 버튼은 두 API 제공 (병행 유지):**
  - `CustomButton(action:title:config:isEnable:trailingIcon:)` — Config 기반, 기존 호출처 호환
  - `Button { } .ctaButtonStyle(.primary, size: .large, icon: nil)` — `ButtonStyle` 기반
- variant × size 확장 시 `CTAButtonStyle.swift`의 enum에 케이스 추가 → `ComponentToken.Button.*`을 통해 색 분기
- pressed 상태는 `configuration.isPressed`로 토큰의 `.Background.pressed` 색을 사용 (opacity 변경 X)

### 새 파일 추가 시 Tuist 재생성 필수

`Project.swift`의 `sources: ["Sources/**"]` glob이 새 파일을 자동 픽업하지만, xcodeproj 동기화는 별도:
```bash
tuist generate --no-open --path Projects/Shared/DesignSystem
```
재생성 전 SourceKit 에러가 떠도 실제 빌드는 정상일 수 있으니, **항상 `xcodebuild`로 실 빌드 확인**할 것.

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
