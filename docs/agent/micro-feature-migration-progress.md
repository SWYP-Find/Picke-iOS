# 마이크로 피쳐 전환 진행 기록

## 완료된 작업

### 1. Sentry 중복 링크 경고 제거

- App 이 `Sentry` 와 `SentrySwiftUI` 를 동시에 직접 링크하지 않도록 정리했다.
- `-all_load` 를 제거해 Sentry Objective-C class 가 앱 바이너리에 중복 로드되는 원인을 줄였다.
- Sentry 관련 package product 는 현재 안전한 static 설정을 유지한다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 2. Presentation 마이크로 피쳐 기반 추가

- `ModuleTarget` 기준으로 `interface`, `implementation`, `testing` 타깃 경로를 표현할 수 있게 했다.
- `Project.makeMicroFeature` 를 추가해 `<Feature>Interface`, `<Feature>`, `<Feature>Testing`, `<Feature>Tests` 타깃을 같은 규칙으로 만들 수 있게 했다.
- Joongna 스타일 호출을 위해 `Project.configure(moduleType: .feature(name: ...))` wrapper 를 추가했다.
- `Auth`, `Battle`, `Chat`, `Notification`, `Splash`, `Web` 에 Interface/Testing placeholder target 을 추가했다.
- Presentation umbrella 가 전체 feature implementation 을 조립하도록 확장했다.

검증:

- `./tuisttool generate` 성공.

### 3. Notification badge 재점등 방지

- 홈 bundle 응답의 `newNotice` 값이 이미 읽음 처리된 notification badge 를 다시 살리지 않도록 reducer 갱신 경로를 정리했다.
- 관련 reducer test 를 추가했다.

검증:

- 전체 통합 시나리오 검증은 아직 남아 있다.

### 4. App 레이어 MainTab 조립 전환

- 기존 `MainTabCoordinator` 의 동작을 보존해 `AppMainTabCoordinator` 로 App 타깃에 옮겼다.
- 기존 `MainTabView` 의 탭 UI 조립을 `AppMainTabView` 로 App 타깃에 옮겼다.
- `AppReducer` / `AppView` 는 더 이상 `MainTabCoordinator` / `MainTabView` 를 직접 사용하지 않는다.
- `Presentation` umbrella 가 `Home`, `Hifi`, `Battle`, `Profile` 을 re-export 하도록 확장했다.
- App target 은 직접 feature implementation 을 추가로 의존하지 않고, 기존처럼 Presentation umbrella 를 통해 조립한다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 5. MainTab 모듈 낮추기

- MainTab 모듈에서 기존 `MainTabCoordinator` / `MainTabView` 구현을 제거했다.
- `MainTabInterface`, `MainTab`, `MainTabTesting` placeholder target 구조로 낮췄다.
- MainTab implementation 이 더 이상 `Home`, `Hifi`, `Battle`, `Profile` implementation 을 직접 의존하지 않는다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 6. Joongna 스타일 `Project.configure` 단일 진입점 정렬

- `ProjectModuleType` 을 `ModuleType` 으로 정리하고, App / feature / 일반 module 을 모두 `Project.configure(...)` 로 생성하도록 맞췄다.
- Presentation feature 는 문자열 기반 `.feature(name: "Home")` 대신 카탈로그 기반 `.feature(.Home)` 형태로 변경했다.
- App, Domain, Data, Network, Shared, Presentation umbrella 의 `Project.swift` 도 `makeModule` / `makeAppModule` 직접 호출 대신 `Project.configure` 를 사용한다.
- `Home`, `Hifi`, `Profile` 에 `Interface` / `Testing` placeholder target 을 추가해 모든 Presentation feature 가 micro-feature target 구조를 갖게 했다.
- `WebInterface`, `NotificationInterface` 에 route/delegate 계약의 첫 타입을 추가했다. 구현 전환은 아직 하지 않고, 다음 단계에서 implementation 직접 의존 제거에 사용한다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 7. Tuist helper 파일 분리 정리

- Joongna 구조처럼 `ModuleType.swift`, `Project+Template.swift`, `Project+App.swift`, `Project+Feature.swift`, `Project+Module.swift`, `Project+Target.swift` 로 helper 책임을 분리했다.
- `Project+Template.swift` 는 `Project.configure(...)` 단일 진입점만 유지한다.
- App / 일반 module / feature target 생성 로직은 각각 별도 파일로 이동했다.
- 기존 Picke 설정인 `bundleId`, `settings`, `resources`, `scripts`, `hasTests`, `schemes` 전달 방식은 그대로 보존했다.

검증:

- `./tuisttool generate` 성공.

### 8. Auth-Web 조립 책임 App 레이어 이동

- App 타깃에 `AppAuthCoordinator` / `AppAuthCoordinatorView` 를 추가했다.
- 로그인 / 온보딩 / 약관 WebView 라우팅 동작은 App 조립 레이어에서 그대로 처리한다.
- `AppReducer` / `AppView` 는 인증 플로우에서 `AuthCoordinator` 대신 `AppAuthCoordinator` 를 사용한다.
- Auth 모듈의 `AuthCoordinator` 는 `LoginFeature` / `OnBoardingFeature` 만 보도록 낮췄다.
- Auth 모듈의 `.Presentation(.Web, .implementation)` 의존을 제거했다.
- App 조립 레이어에서 `LoginView` 를 생성할 수 있도록 `LoginView.init(store:)` 를 public 으로 열었다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 9. Profile-Web/Notification 조립 책임 App 레이어 이동

- App 타깃에 `AppProfileCoordinator` / `AppProfileCoordinatorView` 를 추가했다.
- 마이페이지의 알림 목록 / 약관 WebView / 탈퇴 화면 라우팅 동작은 App 조립 레이어에서 그대로 처리한다.
- `AppMainTabCoordinator` / `AppMainTabView` 의 myPage 탭은 `ProfileCoordinator` 대신 `AppProfileCoordinator` 를 사용한다.
- Profile 모듈의 `ProfileCoordinator` 는 Profile 내부 화면만 보도록 낮췄다.
- Profile 모듈의 `.Presentation(.Web, .implementation)` / `.Presentation(.Notification, .implementation)` 의존을 제거했다.
- App 조립 레이어에서 사용할 수 있도록 Presentation umbrella 가 Notification 구현도 re-export 한다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 10. Home/Hifi/Battle-Chat/Notification 조립 책임 App 레이어 이동

- App 타깃에 `AppHomeCoordinator` / `AppHomeCoordinatorView` 를 추가했다.
- App 타깃에 `AppHifiCoordinator` / `AppHifiCoordinatorView` 를 추가했다.
- App 타깃에 `AppBattleCoordinator` / `AppBattleCoordinatorView` 를 추가했다.
- Home / Hifi / Battle 탭에서 Chat, ChatRoom, Notification 으로 이동하는 기존 라우팅 동작은 App 조립 레이어에서 그대로 처리한다.
- `AppMainTabCoordinator` / `AppMainTabView` 는 Home / Hifi / Battle 탭도 App 조립 코디네이터를 사용한다.
- Home / Hifi / Battle 모듈의 coordinator 는 각 모듈 내부 루트 화면만 보도록 낮췄다.
- Home / Hifi / Battle 모듈의 Chat / Notification implementation 의존을 제거했다.
- App 조립 레이어에서 사용할 수 있도록 Presentation umbrella 가 Chat 구현도 re-export 한다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 11. Interface route 계약 실제 연결

- `ChatInterface` 에 `ChatRoute`, `ChatRoomRoute`, `ChatDelegate`, `ChatRoomDelegate` 를 추가했다.
- `NotificationInterface` 에 `NotificationRoute` 를 추가했다.
- `WebReducer.State`, `NotificationCoordinator.State`, `ChatCoordinator.State`, `ChatRoomFeature.State` 가 Interface route 로 초기화될 수 있게 했다.
- App 조립자는 Web / Notification / Chat 구현 State 를 primitive 값 대신 Interface route 계약으로 생성한다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

### 12. Joongna식 helper catalog/buildableFolders 정리

- Presentation feature catalog 를 `PresentationFeatureModule` 한 곳으로 모았다.
- `.Presentation(...)` dependency/path helper 를 `ProjectTemplatePlugin` 으로 옮겨 `Project.configure(.feature(...))` 와 같은 catalog 를 사용하게 했다.
- `DependencyPlugin` 의 `ModulePath.Presentations` / Presentation 전용 path/dependency helper 를 제거했다.
- App 스킴 생성 규칙을 `Scheme.appSchemes(appName:)` helper 로 옮겨 App `Project.swift` 에서 로컬 함수를 제거했다.
- App / 일반 module / feature implementation / Interface / Testing / Tests target 을 `buildableFolders` 기반으로 생성한다.
- Feature Interface target 은 `Interface`, Testing target 은 `Testing`, Tests target 은 `Tests` 루트 폴더를 buildable folder 로 사용한다.

검증:

- `./tuisttool generate` 성공.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build` 성공.

## 남은 작업

### 1. Feature 간 implementation 직접 의존 제거

현재 feature 모듈의 직접 implementation 의존:

```text
없음
```

남은 정리:

1. 실제 시뮬레이터에서 각 탭의 Chat / Notification / Web 이동을 수동 smoke test 한다.

완료 조건:

- feature implementation 이 다른 feature implementation 을 직접 import 하지 않는다.
- 기존 navigation/deeplink/로그아웃/알림 badge 동작이 유지된다.

### 2. Micro-feature 계약 확장

- `WebDelegate`, `NotificationDelegate` 를 실제 reducer/coordinator 액션과 연결한다.
- 각 feature 의 delegate/output contract 를 App 조립자에서 처리할 수 있는 형태로 확장한다.

완료 조건:

- `Auth`, `Profile` 의 Web/Notification 구현 조립은 App 레이어에만 존재한다.
- `Home`, `Hifi` 의 Notification 이동 계약은 `NotificationInterface` 에 있다.
- `Battle`, `Home`, `Hifi` 의 Chat 이동 계약은 `ChatInterface` 에 있다.

### 3. 검증 루틴

각 단계마다 아래 순서로 검증한다.

```sh
./tuisttool generate
xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

동작 변경 가능성이 있는 reducer 변경은 target test 를 먼저 추가하거나 갱신한다.
