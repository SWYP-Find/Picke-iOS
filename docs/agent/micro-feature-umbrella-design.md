# Presentation 마이크로 피쳐 Umbrella 설계

## 목표

Picke 의 Presentation 계층을 Joongna 의 마이크로 피쳐 umbrella 구조처럼 전환한다. 단, 현재 Presentation feature 들이 서로 implementation 을 직접 의존하고 있으므로 한 번에 전면 교체하지 않는다.

목표는 다음 순서다.

1. 기존 빌드 구조를 유지한 채 Tuist DSL 과 umbrella 조립 규칙을 먼저 추가한다.
2. App 은 Presentation umbrella 하나만 의존하게 만든다.
3. Feature 를 하나씩 `Interface` / `Implementation` / `Testing` 으로 분리한다.
4. Feature 간 직접 implementation 의존을 interface 의존으로 줄인다.
5. MainTab 이 탭 feature 구현을 직접 조립하지 않게 하고, App 조립 레이어에서 탭 feature 들을 묶는다.

## 목표 구조

```text
Projects/Presentation/
├── Presentation/
│   ├── Project.swift
│   └── Sources/
├── Home/
│   ├── Project.swift
│   ├── Interface/Sources/
│   ├── Sources/
│   ├── Testing/Sources/
│   └── Tests/Sources/
├── Chat/
├── Battle/
├── MainTab/
├── Hifi/
├── Profile/
├── Notification/
├── Auth/
├── Splash/
└── Web/
```

## 모듈 규칙

- `Presentation` umbrella target 은 모든 feature implementation target 을 묶는다.
- App target 은 기본적으로 `.Presentation(implements: .Presentation)` umbrella 를 의존한다.
- Feature implementation 은 다른 feature 의 interface 에만 의존하는 것을 목표로 한다.
- 마이그레이션 완료 후 feature implementation 이 다른 feature implementation 을 직접 의존하면 안 된다.
- cross-feature navigation contract, delegate action, public input model, route-facing type 은 `FeatureInterface` 에 둔다.
- Reducer, SwiftUI View, coordinator 구현, 로컬 component, presentation 전용 model 은 `Feature` implementation 에 둔다.
- test double, fixture state, preview helper, dependency mock 은 `FeatureTesting` 에 둔다.
- MainTab 은 탭 shell 과 탭 enum 중심으로 낮추고, Home/Hifi/Battle/Profile 조립은 App 레이어에서 담당한다.

## 현재 Picke 제약

현재 Presentation implementation 직접 의존:

```text
Auth -> Web
Battle -> Chat
Hifi -> Chat, Notification
Home -> Chat, Notification
MainTab -> Home, Hifi, Battle, Profile
Profile -> Web, Notification
```

이 의존은 단계적으로 줄여야 한다. `MainTab`, `Home`, `Battle`, `Chat` 은 route/coordinator 관계를 많이 들고 있어 가장 위험도가 높다.

## Tuist DSL

Picke 는 이미 `ModulePath.Presentations` 와 `.Presentation(implements:)` 를 사용한다. 별도 네이밍 체계를 새로 만들지 말고 기존 DSL 을 확장한다.

```swift
public enum ModuleTarget {
  case interface
  case implementation
  case testing
}

public extension TargetDependency {
  static func Presentation(
    _ module: ModulePath.Presentations,
    _ target: ModuleTarget = .interface
  ) -> TargetDependency
}
```

타깃 이름:

```text
HomeInterface
Home
HomeTesting
HomeTests
```

경로 규칙:

```text
Projects/Presentation/Home/Interface
Projects/Presentation/Home
Projects/Presentation/Home/Testing
```

기존 `.Presentation(implements:)` 는 마이그레이션 중에도 유지한다. 내부 구현은 `.implementation` alias 로 맞춘다.

## Project Helper

마이크로 피쳐 타깃을 같은 규칙으로 만들기 위한 helper 를 추가한다.

```swift
public static func makeMicroFeature(
  name: String,
  bundleId: String,
  dependencies: [TargetDependency] = [],
  interfaceDependencies: [TargetDependency] = [],
  testingDependencies: [TargetDependency] = []
) -> Project
```

생성 타깃:

- `<Feature>Interface`
- `<Feature>`
- `<Feature>Testing`
- `<Feature>Tests`

기본 의존 규칙:

- `<Feature>Interface`: `interfaceDependencies`
- `<Feature>`: `<Feature>Interface` + `dependencies`
- `<Feature>Testing`: `<Feature>Interface` + `<Feature>` + `testingDependencies`
- `<Feature>Tests`: `<Feature>` + `<Feature>Testing`

## 마이그레이션 계획

### 1단계: 기반 추가

- `ModuleTarget` 을 추가한다.
- interface, implementation, testing target 용 path/dependency helper 를 추가한다.
- `makeMicroFeature` 를 추가한다.
- 기존 feature 동작은 그대로 유지한다.

완료 조건:

- `tuist generate` 성공.
- runtime 동작 변화 없음.

### 2단계: Umbrella 확장

`Projects/Presentation/Presentation/Project.swift` 가 현재 모든 Presentation feature implementation 을 포함하도록 확장한다.

```text
Splash, Auth, MainTab, Web, Home, Chat, Hifi, Battle, Profile, Notification
```

App 이 직접 feature 를 여러 개 물고 있다면 Presentation umbrella 하나로 정리한다.

완료 조건:

- `tuist generate` 성공.
- `xcodebuild ... Picke-Debug ... build` 성공.

### 3단계: 저위험 Feature 분리

`Web` 또는 `Notification` 부터 시작한다.

public contract 만 아래로 이동한다.

```text
Projects/Presentation/Web/Interface/Sources
Projects/Presentation/Notification/Interface/Sources
```

구현 코드는 기존 `Sources` 에 유지한다.

완료 조건:

- 기존 import compile.
- 동작 변화 없음.
- test/build 통과.

### 4단계: 의존 방향 정리

직접 implementation 의존을 한 번에 하나씩 interface 의존으로 바꾼다.

```text
Auth -> WebInterface
Profile -> WebInterface, NotificationInterface
Hifi -> NotificationInterface
Home -> NotificationInterface
```

`Chat`, `Battle`, `Home`, `MainTab` 은 reducer 를 먼저 옮기지 않는다. route-facing contract 와 delegate type 을 먼저 옮긴 뒤 coordinator 조립을 바꾼다.

완료 조건:

- 마이그레이션 완료 feature 의 implementation 이 다른 feature implementation 을 import 하지 않는다.
- implementation 조립은 umbrella/App 조립 레이어에서만 한다.

### 5단계: 고위험 Feature 분리

순서:

1. `Chat`
2. `Battle`
3. `Home`
4. `Hifi`
5. `Profile`
6. `MainTab`

`MainTab` 은 Home, Hifi, Battle, Profile 을 조립하고 있으므로 마지막에 옮긴다. 단, 사용자가 요구한 최종 형태는 MainTab 이 직접 조립하지 않고 App 이 조립하는 구조다.

## Interface 에 둘 수 있는 것

허용:

- public route/input model
- delegate action contract
- navigation-facing enum wrapper
- feature identity constant
- 다른 feature 가 참조해야 하는 interface protocol

금지:

- SwiftUI view
- reducer
- `StoreOf<Feature>` construction
- feature implementation component
- Repository/UseCase dependency key
- DesignSystem 전용 UI helper

## 검증

각 마이그레이션 단계마다 아래를 실행한다.

```sh
./tuisttool generate
xcodebuild -workspace Picke.xcworkspace -scheme Picke-Debug -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

feature 분리가 reducer 동작을 바꾸면 build 검증 전에 해당 feature test 를 추가하거나 갱신한다.

## Package Product Type 정책

Joongna 는 여러 package product 를 `.framework` 로 유지할 수 있지만, Picke 는 지금 그 설정을 그대로 복사하면 안 된다.
Picke 는 이미 `Sentry` 와 `SentrySwiftUI` 를 동시에 직접 링크하고 `-all_load` 로 Objective-C class 를 앱 바이너리에 강제로 끌어오면서 Sentry duplicate-class runtime 문제가 났다.

마이그레이션 중 정책:

- `-all_load` 제거 상태를 유지한다.
- App 은 `Sentry` 와 `SentrySwiftUI` 를 동시에 직접 의존하지 않고 `SentrySwiftUI` 만 직접 의존한다.
- feature graph 가 단순해질 때까지 현재 Sentry-safe package product setting 을 유지한다.
- App 이 Presentation umbrella 를 통해 feature implementation 을 조립하고, feature 간 implementation 직접 의존이 사라진 뒤 `.framework` 전환을 재검토한다.

`.framework` 재검토 기준:

- `tuist generate` 에 Sentry duplicate dependency warning 이 없다.
- `xcodebuild` 가 성공한다.
- simulator runtime log 에 `Class Sentry... implemented in both` 가 나오지 않는다.
- App 이 흩어진 직접 implementation 의존 대신 umbrella/App 조립 레이어를 통해 feature implementation 을 링크한다.

## 첫 구현 단위

추천 순서:

1. Tuist `ModuleTarget` 과 helper API 를 추가한다.
2. Presentation umbrella 의존성을 모든 feature implementation 으로 확장한다.
3. `tuist generate` 와 build 를 실행한다.

첫 구현 단위에서는 feature source 이동까지 같이 하지 않는다. 첫 PR/커밋은 인프라와 graph composition 으로 제한한다.
