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

#### 🧱 `@ViewBuilder` + `private func` — 모든 sub-view 는 함수 형태 (필수)

분리한 sub-view 는 **자식 개수 / 분기 유무와 상관없이 무조건 `@ViewBuilder` + `private func` 형태** 로 통일한다.

`private var ...: some View` 형태는 **금지** — 모든 sub-view 는 호출부에서 일관되게 `()` 호출이 보이도록 함수 형태로만 작성한다.

```swift
// ✅ 다중 자식 / 분기 / 반복
@ViewBuilder
private func hotBattlesSection() -> some View {
  VStack(alignment: .leading, spacing: 12) {
    HomeSectionHeader(title: "지금 뜨는 배틀") { send(.seeMoreTapped(.hotBattles)) }
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        ForEach(store.hotBattles) { HotBattleCardView(battle: $0) }
      }
    }
  }
}

@ViewBuilder
private func thumbnail(url: URL?) -> some View {
  if let url {
    KFImage(url).resizable().scaledToFill()
  } else {
    Color.neutral200
  }
}

// ✅ 단일 뷰여도 함수 형태로
@ViewBuilder
private func primaryButton() -> some View {
  CustomButton(
    action: { send(.primaryButtonTapped) },
    title: "사전 투표하기",
    config: CustomButtonConfig.primary(.large, height: 52),
    isEnable: store.isPrimaryButtonEnabled
  )
}

// ❌ 금지 — sub-view 를 var 로 선언
private var primaryButton: some View { ... }
private var section: some View { VStack { ... } }
```

규칙:
- **모든 sub-view = `@ViewBuilder private func name() -> some View`** (단일 뷰 / 다중 자식 / 분기 무관)
- `private var ...: some View` 패턴 금지 — 호출부에서 `name` vs `name()` 형태 혼재되는 것을 방지
- `body` 만 `var body: some View` 유지 (View 프로토콜 요구사항)
- body 안에서 호출은 항상 `()` 가 붙은 함수 형태로 — 가독성 통일

#### 📏 함수 시그니처 — 파라미터 2개 이상이면 멀티 라인 (필수)

함수 파라미터가 **2개 이상이면 각 파라미터를 새 줄에** 풀어 쓴다. 인라인 한 줄 시그니처는 1-파라미터 이하에서만 허용.

```swift
// ✅ 파라미터 2개 이상 — 멀티 라인
@ViewBuilder
private func voteSide(
  _ option: VoteOptionSummary,
  alignment: HorizontalAlignment
) -> some View {
  VStack(alignment: alignment, spacing: 6) { ... }
}

@ViewBuilder
private func optionButton(
  _ choice: Choice,
  label: String,
  desc: String,
  isCorrect: Bool
) -> some View { ... }

// ✅ 파라미터 0~1개 — 한 줄 OK
@ViewBuilder
private func navigationBar() -> some View { ... }

@ViewBuilder
private func filterButton(_ filter: CommentFilter) -> some View { ... }

// ❌ 금지 — 파라미터 2개 이상을 한 줄로
private func voteSide(_ option: VoteOptionSummary, alignment: HorizontalAlignment) -> some View
private func resultBadge(isSelected: Bool, isCorrect: Bool) -> some View
```

규칙:
- View 함수 / Reducer 헬퍼 / 일반 메서드 / init 모두 동일 — 파라미터 ≥ 2 → 멀티 라인
- 호출부 (call site) 도 동일 — `.init(a: x, b: y, c: z)` 처럼 인자 ≥ 2 면 멀티 라인 권장 (이미 대다수 코드 이 패턴)
- 닫는 `)` 와 `-> some View` 는 시그니처 끝줄에 함께

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

`SwiftUI.Color` 의 정적 멤버로 디자인 토큰 (`neutral50` … `neutral900`, `primary50` … `primary900`, `secondary50` …, `beige50` … `beige900`, `bgSubtle`) 이 등록되어 있어 **ShapeStyle 을 받는 모든 modifier 에서 점 단축형 사용**:

```swift
// ✅ 점 단축형 — ShapeStyle 컨텍스트 모두 적용
.foregroundStyle(.neutral900)
.fill(.beige200)
.stroke(.beige700, lineWidth: 1)
.background(.beige50, in: RoundedRectangle(cornerRadius: 2))
.tint(.primary500)

// ❌ 금지 — Color 타입 명시
.foregroundStyle(Color.neutral900)
.fill(Color.beige200)
.stroke(Color.beige700, lineWidth: 1)
.background(Color.beige50, in: ...)
```

> **예외:** `Color` 가 View 자체로 쓰여 메서드 체이닝을 받는 경우는 그대로 둔다.
> ```swift
> Color.beige50.ignoresSafeArea()        // ✅ View 로 쓰임 — Color 명시 필요
> Color.neutral500.opacity(0.4)           // ✅ View 로 쓰임 — Color 명시 필요
> ```

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

#### 🪟 State 초기값 — inline default + `public init() {}` 만 노출

`@ObservableState` 의 `State` 는 프로퍼티마다 **inline default 값**을 박고, `public init() {}` 만 외부에 노출한다. 긴 파라미터 리스트의 `public init(x:, y:, ...)` 는 쓰지 않는다.

```swift
// ✅ 올바른 패턴 — 외부는 .init() 만 호출, 변경은 reducer 내부에서
@ObservableState
public struct State: Equatable {
  public var isLoading: Bool = false
  public var newNotice: Bool = false
  public var heroes: [HeroBattle] = []
  public var heroIndex: Int = 0
  public var hotBattles: [HotBattle] = []

  public var currentHero: HeroBattle? { heroes[safe: heroIndex] }

  public init() {}
}

// ❌ 금지 — 모든 필드를 init 파라미터로 펼침
public init(
  isLoading: Bool = false,
  newNotice: Bool = false,
  heroes: [HeroBattle] = [],
  heroIndex: Int = 0,
  hotBattles: [HotBattle] = []
) {
  self.isLoading = isLoading
  // …
}
```

근거:
- 호출처는 `Feature.State()` 한 줄이면 충분 — 사용 시점에 노이즈 없음
- 초기값은 한 곳에서만 정의 — 프로퍼티 추가/제거 시 init 도 따라 고칠 일 없음
- 테스트/프리뷰에서 다른 값을 넣고 싶으면 `var state = Feature.State(); state.heroes = ... ` 로 직접 mutate
- Shared / Presents / AppStorage 도 동일하게 inline 으로 선언 (`@Shared(...) var foo: Foo = .empty`)

레퍼런스: `HomeFeature.State`, attendance `ProfileFeature.State`

#### 📦 Feature 화면 모델 / Item / Filter / Sort 는 Entity 모듈에 정의 (필수)

`XxxFeature.swift` 안에 `XxxItem` · `XxxSummary` · `XxxFilter` · `XxxSort` 같은 **화면용 모델 / 분기 enum** 을 직접 선언하지 않는다. 모두 `Domain/Entity` 모듈에 정의하고 Feature/View 에서는 `import Entity` 로 가져다 쓴다.

```swift
// ✅ 올바른 패턴 — 화면 모델은 Entity 모듈에 정의
// Projects/Domain/Entity/Sources/Home/Comment.swift
public struct CommentItem: Equatable, Identifiable { ... }
public enum CommentFilter: String, CaseIterable, Equatable { ... }
public enum CommentSort: String, CaseIterable, Equatable { ... }
public struct VoteSummary: Equatable { ... }

// Projects/Presentation/Chat/Sources/Comment/Reducer/CommentFeature.swift
import Entity

@Reducer
public struct CommentFeature {
  @ObservableState
  public struct State: Equatable {
    public var comments: [CommentItem] = []
    public var selectedFilter: CommentFilter = .all
    public var selectedSort: CommentSort = .popular
    public var voteSummary: VoteSummary = .empty
  }
}

// ❌ 금지 — Feature 파일 안에 모델을 같이 선언
// CommentFeature.swift
public struct CommentItem: Equatable, Identifiable { ... }   // ← Entity 로 이동
public enum CommentFilter: ... { ... }                       // ← Entity 로 이동
public struct VoteSummary: Equatable { ... }                 // ← Entity 로 이동
```

규칙:
- **모든 화면 모델 (struct/enum)** 은 `Projects/Domain/Entity/Sources/<도메인>/` 아래에 둔다 (`Home/Comment.swift`, `Home/Battle.swift` 등)
- Feature 안에는 `State` / `Action` / `Reducer` / `CancelID` 같은 **TCA 컴포넌트만** 둔다
- UI 분기용 enum (`CommentFilter`, `CommentSort`) 도 도메인 모델로 취급해 Entity 에 둔다 — 같은 도메인의 여러 화면에서 재사용 가능
- 서버 응답 매핑 init (`init(item: BattlePerspective, order: Int)`) · 정적 mocks · `.empty` 팩토리도 모두 Entity 쪽에서 정의
- 의존성 방향 유지: `Presentation → Domain ← Data` — Entity 는 SwiftUI/TCA/Network 비의존 (Foundation 만)

레퍼런스: `Entity/Sources/Home/Comment.swift` (CommentItem, CommentFilter, CommentSort, CommentReplyItem, VoteSummary)

#### 🗂️ Feature 파일 — Reducer 관련 코드만 (필수)

`XxxFeature.swift` 안에는 **TCA Reducer 구성 요소만** 둔다. presentation 전용 helper 라도 모델/타입은 nested 로 두지 말고 **같은 모듈의 `Model/` 폴더에 별도 파일**로 분리한다.

```swift
// ✅ Feature 파일은 reducer 구성 요소만
@Reducer
public struct PreVoteFeature {
  @ObservableState
  public struct State: Equatable {
    public var shareItem: ShareItem?     // ← top-level 타입 참조
    // …
  }

  public enum Action: ViewAction, BindableAction { … }
  public enum View { case shareTapped(snapshot: Data?) … }
  public enum AsyncAction: Equatable { case prepareShare(ShareContent) … }
  public enum InnerAction: Equatable { case sharePrepared(ShareItem) … }
  nonisolated enum CancelID: Hashable { … }

  @Dependency(\.battleUseCase) private var battleUseCase
  public var body: some Reducer<State, Action> { … }
}

// Projects/Presentation/Chat/Sources/Vote/Model/ShareItem.swift
public struct ShareItem: Equatable, Identifiable { … }

// Projects/Presentation/Chat/Sources/Vote/Model/ShareContent.swift
public struct ShareContent: Equatable { … }

// ❌ 금지 — Feature 안에 nested 로 같이 선언
@Reducer
public struct PreVoteFeature {
  public struct ShareItem: Equatable, Identifiable { … }    // ← Model/ 로 분리
  public struct ShareContent: Equatable { … }                // ← Model/ 로 분리
}
```

규칙:
- Feature 파일 (`XxxFeature.swift`) 에는 **`State` / `Action` / `View` / `AsyncAction` / `InnerAction` / `ScopeAction` / `DelegateAction` / `CancelID` / `body` / `@Dependency` 만** 둔다
- presentation 전용 모델 (`ShareItem`, `ShareContent`, sheet item 등) 은 **같은 모듈의 `Model/` 폴더에 top-level public struct/enum** 으로 분리
- 도메인 모델은 [위 규칙](#-feature-화면-모델--item--filter--sort-는-entity-모듈에-정의-필수) 대로 `Domain/Entity` 모듈로
- presentation 모델에 포함되는 헬퍼 (텍스트 빌드 같은 표현 로직) 는 모델 파일 안에 computed property / method 로 함께 둔다 — reducer 가 책임지지 않는다
- Reducer 안의 helper 함수 (`makeBattle(from:)`, `handleViewAction(state:action:)` 등) 는 Feature 파일에 그대로 둬도 OK — reducer 관련이라는 점이 명확하면 분리 강제하지 않음
- 파일 위치: `Projects/Presentation/<모듈>/Sources/<도메인>/Model/<TypeName>.swift`
- 레퍼런스: `Projects/Presentation/Chat/Sources/Vote/Model/ShareItem.swift`, `Projects/Presentation/Chat/Sources/Vote/Model/ShareContent.swift`

#### 🧰 공통 유틸 — `Utill` 모듈 + `Type+.swift` 네이밍 (필수)

도메인/화면에 종속되지 않는 **순수 유틸** (숫자 포맷, 문자열 분할, 날짜 변환 등) 은 Feature 안에 private helper 로 두지 말고 **`Shared/Utill` 모듈에 타입 확장**으로 분리한다. 여러 모듈(Chat / Home / Auth / Hifi 등)에서 공용으로 쓴다.

```swift
// ✅ 올바른 패턴 — Utill 모듈의 타입 확장. 파일명은 `Type+.swift` (기능 접미사 없음, 한 타입당 한 파일)
// Projects/Shared/Utill/Sources/Extension/Int+.swift
public extension Int {
  var decimalFormatted: String { ... }   // 1340 → "1,340"
}

// Projects/Shared/Utill/Sources/Extension/String+.swift
public extension String {
  func splitIntoSentences() -> [String] { ... }
}

// 사용처: import Utill 후 그대로
import Utill
let count = likeCount.decimalFormatted
let lines = script.text.splitIntoSentences()

// ❌ 금지 — Feature/View 안에 private static helper 로 중복 선언
private static func formattedCount(_ n: Int) -> String { ... }   // ← Utill 로 이동
private static func splitSentences(_ t: String) -> [String] { ... } // ← Utill 로 이동
```

규칙:
- **Extension 파일 네이밍은 항상 `Type+.swift`** — 확장 대상 타입 + `+` 만 (기능 접미사 없음). 한 타입 확장은 한 파일에 모은다 (`Int+.swift`, `String+.swift`, `UUID+.swift`, `Color+.swift`, `View+.swift`). 기존 `ShapeStyle+.swift`, `UIColor+.swift` 와 동일 규칙.
- 순수 유틸 (Foundation 만 의존, UI/도메인 무관) → `Projects/Shared/Utill/Sources/Extension/` 에 둔다
- 쓰는 모듈은 `.Shared(implements: .Utill)` 의존성 추가 후 `import Utill`
- DesignSystem 전용 확장(컬러/폰트/모디파이어)은 DesignSystem 모듈에 두되 파일명은 동일하게 `Type+.swift`
- 레퍼런스: `Projects/Shared/Utill/Sources/Extension/Int+.swift`, `String+.swift`, `UUID+.swift`

#### ⚡ AsyncAction — `Result { try await }` + `mapError` + 단일 `Response` Inner 액션

`do/catch + 별도 Loaded / Failed 액션` 분리하지 말고, `Result` 로 감싸서 단일 `xxxResponse(Result<Success, AuthError>)` Inner 액션으로 보낸다. State 캡쳐는 `[키 = state.xxx]` 형태.

```swift
// ✅ 올바른 패턴
public enum InnerAction: Equatable {
  case homeResponse(Result<HomeBundle, AuthError>)
}

case .fetchHome:
  state.isLoading = true
  return .run { [repository = homeRepository] send in
    let result = await Result {
      try await repository.fetchHome()
    }
    .mapError(AuthError.from)
    return await send(.inner(.homeResponse(result)))
  }
  .cancellable(id: CancelID.fetchHome, cancelInFlight: true)

// 핸들러에서 한 자리에서 success/failure 분기
case let .homeResponse(result):
  state.isLoading = false
  switch result {
  case let .success(bundle): /* state 갱신 */
  case let .failure(error):  Log.error("\(error.localizedDescription)")
  }
  return .none

// ❌ 금지 — do/catch 로 두 액션을 발사
return .run { send in
  do {
    let bundle = try await repository.fetchHome()
    await send(.inner(.homeLoaded(bundle)))      // ← 분리됨
  } catch {
    await send(.inner(.homeFailed(error.localizedDescription)))
  }
}
```

규칙:
- 성공/실패 상태 머지 → 하나의 `xxxResponse(Result<Success, AuthError>)` 케이스
- 에러 타입은 `AuthError` 로 통일하고 `AuthError.from(_:)` 로 변환 (이미 Entity 에 정의됨)
- 캡쳐는 `[repository = self.repository, userSession = state.userSession]` 처럼 명시
- `.cancellable(id: CancelID.xxx, cancelInFlight: true)` 로 중복 호출 방지
- 레퍼런스: `AuthUseCaseImpl.withDraw` / `HomeFeature.fetchHome`

#### 🧩 UseCase 강제 — Feature 는 Repository 직접 의존 금지 (필수)

Clean Architecture 의존 방향(`Presentation → Domain ← Data`) 을 지키기 위해 **Feature/Reducer 는 절대로 `@Dependency(\.xxxRepository)` 를 직접 잡지 않는다**. 모든 외부 IO 는 `XxxUseCase` 프로토콜을 통해서만 호출한다.

```swift
// ✅ 올바른 패턴 — Feature 는 UseCase 만 의존
@Reducer
public struct PreVoteFeature {
  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.perspectiveUseCase) private var perspectiveUseCase

  // ... .run { [useCase = battleUseCase] send in
  //       try await useCase.fetchBattle(battleId: battleId)
  //     }
}

// UseCase Impl — Projects/Domain/UseCase/Sources/<도메인>/<Domain>UseCase.swift
// 별도 protocol 만들지 않고 기존 Interface 를 그대로 채택한다 (Attendance_iOS 패턴).
public struct BattleUseCaseImpl: BattleInterface {
  @Dependency(\.battleRepository) private var battleRepository

  public init() {}

  public func fetchBattle(battleId: Int) async throws -> BattleDetail {
    try await battleRepository.fetchBattle(battleId: battleId)
  }
  // ... 나머지 메서드도 동일하게 repository 로 단순 위임
}

extension BattleUseCaseImpl: DependencyKey {
  public static var liveValue = BattleUseCaseImpl()
  public static var testValue = BattleUseCaseImpl()
  public static var previewValue = BattleUseCaseImpl()
}

public extension DependencyValues {
  var battleUseCase: BattleUseCaseImpl {
    get { self[BattleUseCaseImpl.self] }
    set { self[BattleUseCaseImpl.self] = newValue }
  }
}

// ❌ 금지 — Feature 가 Repository 를 직접 잡음
@Reducer
public struct PreVoteFeature {
  @Dependency(\.battleRepository) private var battleRepository   // ← UseCase 거치게
  @Dependency(\.perspectiveRepository) private var perspectiveRepository
}

// ❌ 금지 — UseCase 용 새 protocol 을 별도로 만들기 (Interface 중복 정의)
public protocol BattleUseCase: Sendable { ... }
public struct BattleUseCaseImpl: BattleUseCase { ... }
```

규칙:
- **Feature/Reducer**: `@Dependency(\.<domain>UseCase)` 만 사용 — Repository 키 사용 금지
- **UseCase Impl**: 기존 `XxxInterface` 를 **그대로 채택** (별도 `XxxUseCase` protocol 만들지 않음 — Attendance_iOS `AuthUseCaseImpl: AuthInterface` 패턴)
- **Repository 잡는 방식**: Impl 안에서 `@Dependency(\.xxxRepository) private var xxxRepository` 로 직접 잡고, `public init() {}` 만 노출 (Attendance 패턴)
- **DependencyKey 채택**: Impl 자체에 `extension XxxUseCaseImpl: DependencyKey { liveValue / testValue / previewValue }` 를 모두 정의 — 별도 `enum XxxUseCaseKey` 만들지 않음
- **liveValue / testValue / previewValue 모두 명시**: 세 값 모두 `XxxUseCaseImpl()` 로 동일하게 둠 (Attendance 패턴 — 테스트/프리뷰에서 별도 mock 이 필요해지면 그때 교체)
- **DependencyValues 키 이름**: `<domain>UseCase` (`battleUseCase`, `homeUseCase`, `commentUseCase`, `perspectiveUseCase`) — 키 타입은 `XxxUseCaseImpl` (Interface 가 아닌 Impl)
- **Repository 키 (`battleRepository`, `homeRepository`, …)** 는 UseCase Impl 안에서만 사용. Presentation 에서는 호출 금지
- 동일 도메인의 모든 IO 를 하나의 UseCase 파일에 모음 (multi-method UseCase). 액션 1개짜리 도메인이면 Attendance `FetchMyAttendancesUseCase` 처럼 별도 protocol 1개 + Impl 1개 형태도 OK
- 새 IO 가 추가되면: 1) Repository 메서드 추가 → 2) UseCase Impl 에 위임 메서드 추가 → 3) Feature 에서 UseCase 호출

레퍼런스: `BattleUseCaseImpl`, `HomeUseCaseImpl`, `CommentUseCaseImpl`, `PerspectiveUseCaseImpl`, Attendance_iOS `AuthUseCaseImpl`

#### 🔌 RepositoryImpl — Provider 선언 패턴

Repository 구현체의 `MoyaProvider` 는 `let` 으로 직접 선언하고, init 기본값으로 `.default` / `.authorized` 팩토리를 그대로 사용한다. `Optional + nil 합치기`나 `MoyaProviderPool` 인다이렉션 금지.

```swift
// ✅ 올바른 패턴 — 단일 provider (인증 필요)
public final class HomeRepositoryImpl: HomeInterface, @unchecked Sendable {
  private let provider: MoyaProvider<HomeService>

  public init(
    provider: MoyaProvider<HomeService> = MoyaProvider<HomeService>.authorized
  ) {
    self.provider = provider
  }
}

// ✅ 올바른 패턴 — default + authorized 두 개 필요 (로그인/로그아웃 분리)
public final class AuthRepositoryImpl: AuthInterface, @unchecked Sendable {
  private let provider: MoyaProvider<AuthService>
  private let authProvider: MoyaProvider<AuthService>

  public init(
    provider: MoyaProvider<AuthService> = MoyaProvider<AuthService>.default,
    authProvider: MoyaProvider<AuthService> = MoyaProvider<AuthService>.authorized
  ) {
    self.provider = provider
    self.authProvider = authProvider
  }
}

// ❌ 금지 — Optional + nil 합치기 + Pool 인다이렉션
public init(
  provider: MoyaProvider<AuthService>? = nil,
  authProvider: MoyaProvider<AuthService>? = nil
) {
  self.provider = provider ?? MoyaProviderPool.shared.defaultProvider(for: AuthService.self)
  self.authProvider = authProvider ?? MoyaProviderPool.shared.authorizedProvider(for: AuthService.self)
}
```

규칙:
- 토큰 인증이 필요한 API → `.authorized` (OptimizedSessionManager 인터셉터 부착)
- 로그인/회원가입 같이 헤더 없는 API → `.default` (로그 플러그인만)
- 테스트/프리뷰는 Mock provider 를 init 으로 그대로 주입 — `MockProvider` 변수 따로 둘 필요 없음
- `MoyaProviderPool` 은 더 이상 RepositoryImpl 에서 직접 호출하지 않는다 (필요 시 풀 자체에서 내부적으로 캐시 처리)
- 레퍼런스: `HomeRepositoryImpl`, `AuthRepositoryImpl`, AsyncMoya `MoyaProvider+Factory.default`, `Extension+MoyaProvider+Auth.authorized`

#### 🧭 Coordinator — `extension X { @Reducer public enum XScreen { ... } }` 구조 절대 건드리지 말 것

TCAFlow 기반 Coordinator 의 `XScreen` 정의는 반드시 **별도 extension 의 `@Reducer public enum`** 형태를 유지한다. 마이그레이션 / 리팩터링 / 자동 포맷터 어떤 이유로도 이 구조를 본체 안으로 끌어들이거나 `enum`을 `struct`/`Reducer` 로 바꾸지 말 것.

```swift
// ✅ 올바른 패턴 — extension + @Reducer + public enum + State: Equatable 보조 extension
@FlowCoordinator(screen: "HomeScreen", navigation: true)
public struct HomeCoordinator {
  // … State / Action / handleRoute …
}

// swiftformat:disable extensionAccessControl
extension HomeCoordinator {
  @Reducer
  public enum HomeScreen {
    case home(HomeFeature)
    case preVote(PreVoteFeature)
    case chatRoom(ChatRoomFeature)
  }
}
// swiftformat:enable extensionAccessControl

extension HomeCoordinator.HomeScreen.State: Equatable {}

// ❌ 금지 — Coordinator 본체 안에 enum 을 인라인 선언
public struct HomeCoordinator {
  @Reducer
  public enum HomeScreen { ... }   // 안 됨 (매크로 인식 / Route 추론 깨짐)
}

// ❌ 금지 — 자동 포맷터가 `public extension { enum }` 으로 바꾸도록 방치
public extension HomeCoordinator {
  @Reducer
  enum HomeScreen { ... }   // @Reducer 매크로 확장이 internal 로 생성 → "must be declared public" 에러
}
```

규칙:
- `XScreen` 은 `@Reducer public enum`. struct 로 바꾸지 말 것
- 본체와 분리된 **별도 extension** 안에 선언
- **swiftformat 자동 변환 차단**: 해당 블록 앞뒤로 `// swiftformat:disable extensionAccessControl` / `// swiftformat:enable extensionAccessControl` 주석 페어 필수.
  - 포맷터가 `public extension X { enum XScreen }` 으로 끌어올리면 `@Reducer` 매크로가 만드는 `State` / `Action` / `body` 가 internal 로 생성되어 `enum 'State' must be declared public because it matches a requirement in public protocol 'CaseReducer'` 빌드 에러가 난다.
- `extension Coordinator.XScreen.State: Equatable {}` 보조 conformance 도 같이 유지 (Route diff 비교 필요)
- 라우터 핸들러 (`routerAction`) 안에서 `state.routes.push/pop/goBack` 직접 호출은 OK, 단 `dismiss`/`submit` 같이 반복되는 종료 액션은 `.send(.view(.backAction))` 으로 일원화
- 레퍼런스: `HomeCoordinator`, `AuthCoordinator`, `MainTabCoordinator`

#### 🌐 switch 기반 computed property — 모든 case 에 `return` 명시 유지 (DomainType / BaseTargetType / DependencyKey 공통)

`switch self { ... }` 만으로 값을 돌려주는 computed property 는 **모든 case 에 `return` 키워드를 명시한다**. 적용 범위:

1. **`DomainType.url`** — `PieckeDomain` 같은 도메인 prefix 매핑
2. **`BaseTargetType` 구현체의 `urlPath` / `method` / `parameters` / `task` / `sampleData`** — 모든 Moya TargetType switch
3. **`DependencyKey.liveValue` / `testValue`** — `UnifiedDI.resolve(...) ?? Default...()` 패턴
4. 그 외 단일 표현식 switch 를 본문으로 갖는 computed property 전부

자동 포맷터의 `redundantReturn` 룰이 single-expression switch 에서 `return` 을 떼어내려 하지만, **새 case 추가 시 일부만 implicit / 일부는 explicit 으로 혼합되는 상태가 가장 깨지기 쉽다**. 새 case 추가 후엔 항상 기존 case 까지 같이 `return` 으로 정렬할 것.

```swift
// ✅ DomainType — 모든 case return
extension PieckeDomain: DomainType {
  public var url: String {
    switch self {
    case .auth:    return "api/v1/auth/"
    case .profile: return "api/v1/me/"
    case .home:    return "api/v1/home"
    case .poll:    return "api/v1/poll"
    case .battle:  return "api/v1/battles/"
    }
  }
}

// ✅ BaseTargetType — urlPath / method / parameters 모두 return 명시
extension BattleService: BaseTargetType {
  public var urlPath: String {
    switch self {
    case let .preVote(battleId, _):
      return BattleAPI.preVote(battleId: battleId).description
    case let .scenario(battleId):
      return BattleAPI.scenario(battleId: battleId).description
    }
  }

  public var method: Moya.Method {
    switch self {
    case .preVote:  return .post
    case .scenario: return .get
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case let .preVote(_, body): return body.toDictionary
    case .scenario:             return nil
    }
  }
}

// ✅ DependencyKey — liveValue / testValue 도 return 명시
public struct BattleRepositoryDependency: DependencyKey {
  public static var liveValue: BattleInterface {
    return UnifiedDI.resolve(BattleInterface.self) ?? DefaultBattleRepositoryImpl()
  }
  public static var testValue: BattleInterface {
    return UnifiedDI.resolve(BattleInterface.self) ?? DefaultBattleRepositoryImpl()
  }
}

// ❌ 금지 — 포맷터가 떼어낸 implicit return 혼합
public var method: Moya.Method {
  switch self {
  case .preVote:  .post           // ← 안 됨
  case .scenario: return .get     // ← 혼합 상태
  }
}
```

규칙:
- 새 case 추가 후 포맷터가 기존 case 의 `return` 을 떼어냈다면 **PR 전에 직접 되돌려서 일관성 유지**
- 새 도메인 case (`.battle` 등) / 새 서비스 case (`.scenario` 등) / 새 DI 키 추가 시 모두 동일하게 `return ...` 형태로 작성
- 포맷터가 반복적으로 깨면 해당 파일 또는 함수 블록에 `// swiftformat:disable redundantReturn` 디렉티브 페어 추가 검토
- 레퍼런스: `PieckeDomain`, `BattleService`, `AuthService`, `BattleRepositoryDependency`, `HomeRepositoryDependency`

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

### 📦 커밋 단위 / 크기 규칙 — 30 파일 이상이면 끊어서 (필수)

한 번에 너무 많은 파일을 묶으면 리뷰가 불가능하고 회귀 발생 시 bisect 가 어렵다. 변경된 파일 수가 많으면 **의미 단위로 끊어서 여러 커밋**으로 나눈다.

규칙:
- 한 커밋의 **변경 파일 수가 30개를 초과하면 반드시 분할**
- 분할 기준은 **모듈 / 도메인 / 변경 종류** 가 우선:
  - 예) `API + Service + RepositoryImpl` 같이 도메인 레이어 한 줄기 → 1 커밋
  - 예) `UseCase 신규 정의` → 1 커밋
  - 예) `Feature 들의 @Dependency 교체` → 1 커밋
  - 예) `View / Reducer UI 변경` → 1 커밋
  - 예) `AGENTS.md / .swiftformat 같은 규칙 / 설정` → 1 커밋
- 분할 후 각 커밋은 **단독으로 빌드 가능**해야 함 (의존하는 다른 커밋이 같은 PR 안에 있으면 OK, 다른 PR 에 있으면 분할 순서 조정)
- 작업 시작 전에 변경 범위를 보고 **30 파일이 넘을 것 같으면 미리 단계로 쪼개기**
- 단순 포맷터 / 자동 변환 (예: 전역 시그니처 멀티라인) 은 30 파일 넘어도 1 커밋 OK — 단 커밋 메시지에 "전역 자동 변환" 명시

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

### SwiftUI 전문 가이드 스킬 — `swiftui-expert-skill`
- **출처**: [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) (Agent Skills 오픈 포맷)
- **로컬 설치 위치**
  - Claude Code: `~/.claude/plugins/SwiftUI-Agent-Skill/`
  - Codex: `~/.codex/skills/swiftui-expert-skill/`
  - Cursor 도 동일 폴더를 `Plugins` 가이드대로 등록하면 됨
- **재설치 / 업데이트**
  ```bash
  rm -rf ~/.claude/plugins/SwiftUI-Agent-Skill ~/.codex/skills/swiftui-expert-skill
  git clone https://github.com/AvdLee/SwiftUI-Agent-Skill.git ~/.claude/plugins/SwiftUI-Agent-Skill
  cp -R ~/.claude/plugins/SwiftUI-Agent-Skill/swiftui-expert-skill ~/.codex/skills/swiftui-expert-skill
  ```
- **언제 호출**: SwiftUI 상태관리(`@Observable` / 프로퍼티 래퍼 선택), 뷰 컴포지션, 리스트·내비게이션·시트, Swift Charts, 애니메이션, macOS multi-window, iOS 26+ Liquid Glass, 접근성, Instruments 트레이스 분석.
- **호출 방법**: 프롬프트에 *"swiftui-expert skill 을 사용해 ..."* 형태로 지시하거나, `.trace` 경로/녹화 요청처럼 트리거 키워드가 들어오면 자동 활성화.

### 자동 호출 키워드
다음 키워드 언급 시 **자동으로 성능 최적화 스킬 호출**:
- `ifCaseLet`, `TCA`, `Effect`, `메모리 누수`, `성능`, `최적화`
- `SwiftUI`, `렌더링`, `빌드 시간`, `TCAFlow`, `WeaveDI`
- `Cannot infer`, `Extensions must not`, `Type annotation missing`
- `빌드 오류`, `컴파일 에러`, `SourceKit error`

---

이 문서는 Picke iOS 프로젝트의 **아키텍처 가이드라인**입니다.
새로운 기능 개발이나 코드 리뷰 시 이 가이드와 세부 문서들을 참고하여 일관성 있는 코드를 작성해주세요.
