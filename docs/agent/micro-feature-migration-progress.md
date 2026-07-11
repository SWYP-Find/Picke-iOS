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

## 남은 작업

### 1. MainTab 모듈 낮추기

- 현재 MainTab 모듈에는 기존 coordinator/view 구현이 남아 있다.
- 다음 단계에서 MainTab 을 feature implementation 조립자가 아니라 tab shell/interface 모듈로 낮춘다.
- App 조립 타입과 중복되는 기존 MainTab 구현을 제거하거나 interface-only contract 로 분리한다.

완료 조건:

- App 은 `AppMainTabCoordinator` / `AppMainTabView` 만 사용한다.
- MainTab implementation 이 `Home`, `Hifi`, `Battle`, `Profile` implementation 을 직접 의존하지 않는다.
- `tuist generate` 와 `xcodebuild` 가 통과한다.

### 2. 남은 feature 의 micro-feature Project 전환

- `Home`, `Hifi`, `Profile`, `MainTab` Project 를 `Project.configure(moduleType: .feature(...))` 구조로 전환한다.
- 각 feature 에 Interface/Testing placeholder 를 추가한다.

완료 조건:

- 모든 Presentation feature 가 `Interface` / implementation / `Testing` target 을 가진다.
- `tuist generate` 가 통과한다.

### 3. Feature 간 implementation 직접 의존 제거

현재 남은 직접 implementation 의존:

```text
Auth -> Web
Battle -> Chat
Hifi -> Chat, Notification
Home -> Chat, Notification
Profile -> Web, Notification
```

진행 순서:

1. route/delegate/input contract 를 각 `FeatureInterface` 로 이동한다.
2. 구현 모듈은 상대 feature 의 interface 만 의존하도록 바꾼다.
3. 실제 reducer/view/coordinator 조립은 Presentation umbrella 또는 App 조립 레이어에 둔다.

완료 조건:

- 마이그레이션 완료 feature 의 implementation 이 다른 feature implementation 을 직접 import 하지 않는다.
- 기존 navigation/deeplink/로그아웃/알림 badge 동작이 유지된다.

### 4. 검증 루틴

각 단계마다 아래 순서로 검증한다.

```sh
./tuisttool generate
xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

동작 변경 가능성이 있는 reducer 변경은 target test 를 먼저 추가하거나 갱신한다.
