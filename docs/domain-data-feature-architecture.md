# Domain·Data 레이어 Feature 마이크로아키텍처 재편 설계

> 상태: 설계 문서 (구현 전). 코드/Project.swift 변경 없음.
> 전제: config 재편(Stage=debug, Dev 제거, 외부 패키지 동적화) 완료, 현재 빌드 그린.

---

## 1. 현재 구조 (조사 결과 요약)

### 1.1 Presentation — 목표 패턴 (이미 마이크로피처)

`Projects/Presentation/<Feature>/` 각각 독립 xcodeproj. `Project.configure(moduleType: .feature(.Chat), ...)` 호출 →
`configureFeature` 가 **Interface / 구현 / Testing / Tests 4타깃**을 생성한다
(`Plugins/ProjectTemplatePlugin/.../Project+Feature.swift`).

```swift
// Projects/Presentation/Chat/Project.swift (실측)
let project = Project.configure(
  moduleType: .feature(.Chat),
  bundleId: .appBundleID(name: ".Chat"),
  dependencies: [
    .Domain(implements: .UseCase),   // ← 8개 Presentation feature 전부 동일
    .Shared(implements: .Shared),
    .SPM.composableArchitecture, ...
  ]
)
```

### 1.2 Domain / Data — 레이어 단일 모듈 (재편 대상)

| 모듈 | moduleType | 의존 | 비고 |
|---|---|---|---|
| `Domain/Entity` | `.module` | 없음 | feature 폴더 11개 |
| `Domain/DomainInterface` | `.module` | Entity, weaveDI, TCA | feature 폴더 15개 |
| `Domain/UseCase` | `.module` | DomainInterface, TCA, weaveDI, **mixpanel, googleMobileAds** | feature 폴더 14개 |
| `Domain/Domain` | `.module` | 위 3개 `@_exported` 재노출 | 엄브렐라 |
| `Domain/DomainTesting` | `.module` | UseCase | Analytics/AppUpdate/Auth/Home/Manager 목 |
| `Data/API` | `.module` | asyncMoya | |
| `Data/Model` | `.module` | Entity | |
| `Data/Service` | `.module` | API, Entity, **Foundations** | |
| `Data/Repository` | `.module` | Networking, **Foundations**, Service, Model, DomainInterface, **googleSignIn, mixpanel** | |
| `Data/Data` | `.module` | 4개 `@_exported` 재노출 | 엄브렐라 |
| `Data/DataTesting` | `.module` | Entity, DomainInterface | 목 리포지토리 |

**현재 의존 방향(실측)**: `UseCase → DomainInterface → Entity`,
`Repository → {Service → API, Model, DomainInterface, Foundations}`, `Model → Entity`.
Presentation → `UseCase`(구현체 직접). App → `Presentation`/`Domain`/`Data`/`NetworkModule` 엄브렐라 4종 + DI 등록
(`Projects/App/Sources/Di/DiRegister.swift`, WeaveDI `.register { XxxRepositoryImpl() as XxxInterface }` 29건).

### 1.3 Tuist 스캐폴드 (실측 심볼)

- `Plugins/DependencyPlugin/.../Modules.swift`: `ModulePath.Domains`(Entity/UseCase/Domain/DomainInterface/DomainTesting), `ModulePath.Datas`, `ModulePath.Networks`, `ModulePath.Shareds` enum.
- `Path+Modules.swift` / `TargetDependency+Modules.swift`: `.Domain(implements:)`, `.Data(implements:)` 등 `Projects/<레이어>/<rawValue>` 경로 규칙.
- `Plugins/ProjectTemplatePlugin/.../ModuleType.swift`: `.app` / `.feature(PresentationFeatureModule)` / `.module(name:)` / **`.microModule(name:)`** — `microModule` 은 **정의만 있고 사용처 0곳**, `Project+Template.swift:89` 에서 `configureFeature` 로 위임하므로 **비-Presentation 모듈을 4타깃 마이크로피처로 만드는 통로가 이미 준비돼 있다.**
- `TargetDependency+Presentation.swift`: `ModuleTarget`(.interface/.implementation/.testing) + `.Presentation(_:_:)` 접근자 — Domain/Data 용으로 복제할 패턴.

### 1.4 반복 feature 축

핵심 8축: **Auth, Battle, Comment, Home, Notification, Perspective, Profile, Search**
(4개 레이어 모듈 전부에서 반복). 횡단: AppUpdate, Ad, Analytics, Device, Manager,
OAuth(Apple/Google/Kakao), AudioPlayer, Deeplink, Error, Share, Base/Common.

---

## 2. 목표 토폴로지 — 대안 비교와 결정

### 대안 A — feature별 단일 모듈 (레이어를 폴더로 내장)

`AuthDomain` 1타깃(Entity+Interface+UseCase 폴더), `AuthData` 1타깃(Model+Service+Repository+API 폴더).

- 장점: 모듈 수 최소(~18 xcodeproj), 마이그레이션 가장 단순.
- 단점: **Interface 분리가 없어** Data 가 UseCase 구현까지 물고 리빌드됨. Presentation ↔ Data 가 같은 타깃 경유로 간접 결합. Presentation(4타깃)과 비대칭 → 팀 규약 이원화.

### 대안 B — feature × 레이어 매트릭스 모듈

`Auth-Entity`, `Auth-Interface`, `Auth-UseCase`, `Auth-Model`, `Auth-Service`, `Auth-Repository`, `Auth-API` … 각각 독립 xcodeproj.

- 장점: 경계 최강, 빌드 병렬성 이론상 최대.
- 단점: 8 feature × 6~7 레이어 = **50개+ xcodeproj**. `tuist generate` 시간·스킴·Derived 폭증, Project.swift 유지비 폭증. 1인 개발 규모(Picke)에 명백한 과설계 — karpathy "불필요한 추상화 금지" 위반.

### 대안 C — feature별 Domain 모듈 + feature별 Data 모듈 (추천 ✅)

**"xcodeproj 수는 A 수준, 경계는 B 수준"** — Presentation 이 이미 쓰는 마이크로피처 패턴 그대로.

- `Projects/Domain/<Feature>/` = 1 xcodeproj, 내부 4타깃:
  - `<Feature>DomainInterface` (Entity + Repository 프로토콜 + UseCase 프로토콜) — 기존 Entity/DomainInterface 폴더 병합
  - `<Feature>Domain` (UseCase 구현)
  - `<Feature>DomainTesting` (목 — 기존 DomainTesting·DataTesting 의 해당 feature 목 흡수)
  - `<Feature>DomainTests`
- `Projects/Data/<Feature>/` = 1 xcodeproj, 내부 2타깃:
  - `<Feature>Data` (API + Model + Service + Repository 를 **폴더로** 내장 — Data 내부 레이어는 한 feature 안에서 항상 같이 바뀌므로 타깃 분리 실익 없음)
  - `<Feature>DataTests`
- Data 쪽에 Interface 타깃을 두지 않는 이유: Repository 가 구현하는 계약은 이미 `<Feature>DomainInterface` 에 있다. DataInterface 는 내용이 없는 빈 타깃이 된다 — 단순함 우선.

**추천 근거**
1. **대칭성**: Presentation 과 동일한 4타깃 규약·폴더 구조·스킴 → 학습비용 0. `microModule` case 가 이미 이 용도로 예약돼 있음.
2. **컴파일 격리의 핵심만 취함**: Data 와 Presentation 이 `<Feature>DomainInterface` 에만 의존하면 UseCase 구현 변경 시 Data 리빌드 없음. 반대로 Data 내부(API↔Service↔Repository)는 응집이 높아 쪼개도 격리 이득이 없다.
3. **규모 적합**: xcodeproj 12개 → 22개(+10). B 의 50개+ 대비 관리 가능, A 대비 경계 확보.
4. **부수 빌드 이득**: 현재 `UseCase` 전체가 mixpanel·googleMobileAds 를, `Repository` 전체가 googleSignIn 을 물고 있다 → 분리 후 해당 SPM 은 CommonDomain/AuthData 등 실제 사용 모듈에만 연결.

**엔티티 배치 결정(트레이드오프 명시)**: Entity 를 별도 타깃으로 남기지 않고 `<Feature>DomainInterface` 에 병합한다. Entity 만 쓰는 소비자(Model)가 프로토콜 선언까지 함께 컴파일하지만, Interface 타깃은 선언 위주라 비용이 미미하고 타깃 수 8개를 아낀다. 순수 값 타입과 프로토콜은 같은 "계약" 레이어다.

---

## 3. 모듈 인벤토리 (추천안 C 기준)

### 3.1 Domain 레이어 — 10 xcodeproj

| 모듈 (경로) | 타깃 접두 | 포함 feature (Interface / 구현) | 주요 의존 |
|---|---|---|---|
| `Domain/Auth` | `AuthDomain` | Auth + **OAuth 전체**(Apple/Google/Kakao) | CommonDomainInterface, TCA, weaveDI |
| `Domain/Battle` | `BattleDomain` | Battle | 〃 |
| `Domain/Comment` | `CommentDomain` | Comment | 〃 |
| `Domain/Home` | `HomeDomain` | Home | 〃 |
| `Domain/Notification` | `NotificationDomain` | Notification | 〃 |
| `Domain/Perspective` | `PerspectiveDomain` | Perspective | 〃 |
| `Domain/Profile` | `ProfileDomain` | Profile | 〃 |
| `Domain/Search` | `SearchDomain` | Search | 〃 |
| `Domain/Common` | `CommonDomain` | **횡단**: AppUpdate, Ad, Analytics, Device, Manager, AudioPlayer, Deeplink, Error, Share | TCA, weaveDI, **mixpanel(+SessionReplay), googleMobileAds** |
| `Domain/Domain` | `Domain` (엄브렐라) | 위 9개 `@_exported` | 9개 feature Domain |

- OAuth(Apple/Google/Kakao)는 Auth 의 하위 관심사이므로 `AuthDomain` 으로 흡수 (DomainInterface 의 Apple/Google/Kakao feature 폴더 포함).
- `CommonDomain` 은 "여러 feature 가 공유하는 저변경 횡단 계약"만 담는다. 특정 feature 전용으로 판명되면 그 feature 로 이동 (예: AudioPlayer 가 Hifi/Battle 전용이면 이동 검토 — 마이그레이션 0단계 스캔에서 확정).
- 기존 `DomainTesting`(Analytics/AppUpdate/Auth/Home/Manager 목) + `DataTesting`(목 리포지토리)은 각 `<Feature>DomainTesting` 타깃으로 해체 흡수 — 목의 계약이 DomainInterface 에 있으므로 Domain 쪽 Testing 이 자연스러운 집이다.

### 3.2 Data 레이어 — 10 xcodeproj

| 모듈 (경로) | 타깃 | 포함 (기존 폴더) | 주요 의존 |
|---|---|---|---|
| `Data/Auth` | `AuthData` | API·Model·Service·Repository 의 Auth + OAuth/Google | AuthDomainInterface, CommonData, APIHeaderKit, Networking, asyncMoya, **googleSignIn** |
| `Data/Battle`…`Data/Search` (7개) | `<F>Data` | 각 feature 의 API·Model·Service·Repository | `<F>DomainInterface`, CommonData, APIHeaderKit, Networking, asyncMoya |
| `Data/Common` | `CommonData` | API/Base, Service·Model/Common, AppUpdate·Device·AudioPlayer 리포지토리 | CommonDomainInterface, APIHeaderKit, TokenKit, Networking, asyncMoya, mixpanel |
| `Data/Data` | `Data` (엄브렐라) | 9개 `@_exported` | 9개 feature Data |

### 3.3 전체 그래프 (feature 1개 단면)

```
App ──▶ Presentation(엄브렐라) ──▶ Chat(Presentation) ──▶ BattleDomain ─┐
App ──▶ Domain(엄브렐라)·Data(엄브렐라)  [DI 등록용]                      │
                                                                        ▼
              BattleData ──────────────────────────▶ BattleDomainInterface
                 │  │                                       ▲
                 │  └─▶ CommonData ─▶ CommonDomainInterface │
                 └─▶ APIHeaderKit ─▶ TokenKit    BattleDomain(UseCase 구현)
```

- 모듈(xcodeproj) 수: 현재 12 (Domain 5 + Data 6 + Foundations 1) → **22** (Domain 10 + Data 10 + Network 2).
- 타깃 수: Domain 9×4 + 엄브렐라 1 = 37, Data 9×2 + 1 = 19. Tests/Testing 타깃은 실제 테스트가 있는 feature 만 생성하도록 옵션화(§6) 하면 실효 수는 더 적다.

---

## 4. 엄브렐라(집約) 모듈 전략

### 4.1 현재 상태 (실측)

- `Domain/Domain/Sources/Exported/DomainExported.swift`: `@_exported import Entity/DomainInterface/UseCase`
- `Data/Data/Sources/Exported/DataExported.swift`: `@_exported import API/Model/Repository/Service`
- `Presentation/Presentation/Sources/Exported/PresentationExported.swift`: 9개 feature `@_exported`
- 소비자: **App 뿐** (`App/Project.swift` 가 4개 엄브렐라 참조). Presentation feature 들은 엄브렐라가 아닌 `UseCase` 를 직접 참조 — 이미 올바른 방향.

### 4.2 재편 후 설계

**레이어 엄브렐라 2개 유지, 역할은 "App 조립 전용"으로 한정한다.** feature 엄브렐라(예: AuthDomain 이 AuthData 까지 묶는 것)는 레이어 경계를 붕괴시키므로 만들지 않는다.

```swift
// Domain/Domain/Sources/Exported/DomainExported.swift (재편 후)
@_exported import AuthDomain
@_exported import BattleDomain
// ... 9개 feature Domain (Interface 는 구현 타깃이 이행적으로 노출)

// Data/Data/Sources/Exported/DataExported.swift (재편 후)
@_exported import AuthData
// ... 9개 feature Data
```

### 4.3 엄브렐라 참조 vs 개별 참조 — 트레이드오프와 규칙

| | 엄브렐라 참조 | 개별 모듈 참조 |
|---|---|---|
| 편의 | import 1줄, 신규 feature 추가 시 소비자 무변경 | feature 마다 의존 선언 필요 |
| 빌드 격리 | **전무** — 임의 feature 변경이 엄브렐라 소비자 전체 리빌드 유발 | 변경 feature 의 소비자만 리빌드 (재편의 핵심 목적) |
| 경계 | `@_exported` 로 암시적 전역 import → 경계 침식 | 의존이 Project.swift 에 명시 → tuist graph 로 감사 가능 |

**규칙 (권장안)**
1. **App 만** 엄브렐라(`Domain`, `Data`) 참조 — DI 등록(DiRegister)이 모든 구현체를 봐야 하므로 편의가 격리 손실을 상회한다 (App 은 어차피 전체 의존).
2. **Presentation feature 는 자기 feature 의 Domain 만** 개별 참조: `.Domain(.Chat, .implementation)`. 엄브렐라 참조 금지 — 이걸 어기면 재편 효과가 0이 된다.
3. **Data feature 는 자기 feature 의 DomainInterface 만** 참조. Domain 엄브렐라·타 feature 참조 금지.
4. 기존 `NetworkModule` 엄브렐라(`@_exported import Foundations/Networking/ThirdPartys`)는 Foundations 분할(§5) 후 재노출 목록만 갱신.

---

## 5. Foundations 모듈 재설계

### 5.1 실태 조사 결과

`Projects/Network/Foundations` 의 실체는 **소스 3파일**이 전부다:

| 파일 | 심볼 | 역할 |
|---|---|---|
| `TokenProviding.swift` | `TokenProviding`(프로토콜), `InMemoryTokenProvider`, `DependencyValues.tokenProvider`(WeaveDI/Dependencies 키) | **토큰 저장·제공 추상화** |
| `APIHeader.swift` | `APIHeader` (baseHeader/mutiPartbaseHeader 등 헤더 조립, tokenProvider 로 Bearer 주입) | **HTTP 헤더 조립** |
| `APIHeaderManger.swift` | content-type 상수, csrf 상수 | 헤더 상수 |

소비자 실측 (`import Foundations` 전수):

| 소비자 | 실제로 쓰는 심볼 |
|---|---|
| `Data/Service/*` 9개 서비스 | `APIHeader.baseHeader` 등 — **헤더 조립만** |
| `Data/Repository`(Auth 토큰 갱신 1곳) | `APIHeader` 토큰 갱신 경로 |
| `App/Sources/Di`(DiRegister, KeychainTokenProvider) | `TokenProviding` — **토큰 추상화만** (Keychain 구현체 등록) |
| `Network/NetworkModule` | `@_exported` 재노출 셸 |

즉 "Foundations" 라는 범용 이름과 달리 실체는 **네트워크 인증/헤더 전용**이며, UI·도메인은 전혀 쓰지 않는다. 흔한 Foundations 후보인 Extension 유틸은 이미 `Shared/Utill`(Int+/String+/Date+/UUID+)에, 로깅은 SPM `logMarco` 에 따로 있다. 따라서 "Networking용/Logging용/Extension용/DesignKit용 4분할" 같은 기계적 분할은 **실사용 근거가 없어 기각**한다 (단순함 우선). 실사용 축은 정확히 2개다.

### 5.2 분할·개명안 — 2모듈

| 새 모듈 | 경로 | 포함 심볼 | 의존 | 소비자 |
|---|---|---|---|---|
| **`TokenKit`** | `Projects/Network/TokenKit` | `TokenProviding`, `InMemoryTokenProvider`, `DependencyValues.tokenProvider` | weaveDI, Dependencies | App(Di, Keychain 구현), APIHeaderKit |
| **`APIHeaderKit`** | `Projects/Network/APIHeaderKit` | `APIHeader`, `APIHeaderManger` | **TokenKit** | 각 `<Feature>Data`(Service·Repository), CommonData |

- 이득: App 은 `TokenKit` 만 의존(헤더 조립 코드와 절연), Data 는 `APIHeaderKit` 경유로 필요한 조각만 의존. 이름이 역할을 그대로 말한다.
- `ModulePath.Networks` 에서 `Foundations` case 제거, `TokenKit`/`APIHeaderKit` case 추가. `NetworkModule` 엄브렐라 재노출 목록 갱신.
- 부수 발견 2건 (이번 범위 밖, 별도 이슈 권장): ① `Networking`/`ThirdPartys` 는 재노출 파일 1개뿐인 빈 셸이며 ThirdPartys 의 export 는 주석 처리돼 **사실상 빈 모듈** → 추후 정리 후보. ② `APIHeaderManger.csrf` 에 시크릿 문자열 하드코딩 → 보안 이슈로 분리 추적.

---

## 6. 의존성 규칙 (재편 후 불변식)

1. **레이어 방향**: `Presentation → Domain(Interface|구현)`, `Data → DomainInterface`, `Domain → (하위 없음)`. Presentation→Data, Domain→Data, Domain구현→Presentation 은 **금지**.
2. **feature 간**: 구현 타깃(`<F>Domain`, `<F>Data`) 간 상호 참조 금지. feature A 가 feature B 의 타입이 필요하면 ① 진짜 공유 계약이면 `CommonDomainInterface` 로 승격, ② B 소유가 명확하면 `BDomainInterface` 에만 의존(Interface 는 단방향 참조 허용). Interface→Interface 는 DAG 유지 (tuist graph 로 검증).
3. **컴파일 격리**: 계약(Entity+프로토콜)은 전부 `<F>DomainInterface` 에. 구현 타깃은 계약을 재선언·재노출하지 않는다. Data·Presentation 이 Interface 에만 의존하면 UseCase 구현 변경은 해당 feature Domain 타깃만 리빌드.
4. **엄브렐라**: §4.3 — App 전용. `@_exported` 는 엄브렐라 3종 + NetworkModule 외 신규 도입 금지.
5. **DI**: WeaveDI 등록은 지금처럼 App(DiRegister) 1곳 집중 유지. 모듈별 분산 등록(자기등록 패턴)은 현 규모에 과설계 — 도입하지 않는다.

---

## 7. Tuist 스캐폴드 매핑 (실제 심볼 기준)

### 7.1 ModuleType — 기존 `microModule` 활용, 신규 case 불필요

```swift
// Domain feature — Projects/Domain/Auth/Project.swift (예시)
let project = Project.configure(
  moduleType: .microModule(name: "AuthDomain"),   // 이미 존재, configureFeature 위임
  bundleId: .appBundleID(name: ".AuthDomain"),
  settings: .settings(),
  interfaceDependencies: [ .Domain(.Common, .interface), .SPM.weaveDI, .SPM.composableArchitecture ],
  dependencies: [ .SPM.weaveDI, .SPM.composableArchitecture ]
)

// Data feature — Projects/Data/Auth/Project.swift (예시)
let project = Project.configure(
  moduleType: .module(name: "AuthData"),
  bundleId: .appBundleID(name: ".AuthData"),
  settings: .settings(),
  dependencies: [
    .Domain(.Auth, .interface), .Data(.Common),
    .Network(implements: .APIHeaderKit), .Network(implements: .Networking),
    .SPM.asyncMoya, .SPM.weaveDI, .SPM.googleSignIn,
  ],
  hasTests: true
)
```

- 타깃 이름 규칙: Presentation 이 이미 `Auth`/`Battle`… 타깃명을 점유하므로 **`<Feature>Domain` / `<Feature>Data` 접미사 필수** (워크스페이스 내 타깃명 유일성).
- 개선 1건: `configureFeature` 에 `hasTests`/`hasTesting` 파라미터를 추가해 목·테스트 없는 feature 의 빈 Testing/Tests 타깃 생성을 생략 (타깃 폭증 완화).

### 7.2 접근자 — `TargetDependency+Presentation.swift` 패턴 복제

ProjectTemplatePlugin 에 `TargetDependency+Domain.swift`/`TargetDependency+Data.swift` 신설:

```swift
public enum DomainFeatureModule: String, CaseIterable {
  case Auth, Battle, Comment, Home, Notification, Perspective, Profile, Search, Common
}
public enum DataFeatureModule: String, CaseIterable { /* 동일 9 case */ }

public extension ProjectDescription.Path {
  static func Domain(_ m: DomainFeatureModule, _ t: ModuleTarget) -> Self {
    // Projects/Domain/<rawValue>/{Interface|Sources|Testing}
  }
}
public extension TargetDependency {
  /// 기존 .Domain(implements: ModulePath.Domains) 와 시그니처가 달라 공존 가능 (마이그레이션 기간 병행)
  static func Domain(_ m: DomainFeatureModule, _ t: ModuleTarget = .implementation) -> Self {
    // target: "\(m.rawValue)Domain" + (t == .interface ? "Interface" : t == .testing ? "Testing" : "")
  }
  static func Data(_ m: DataFeatureModule) -> Self  // target: "\(m.rawValue)Data"
}
```

- 기본값을 `.implementation` 으로 (Presentation 은 UseCase 구현을 직접 쓰는 현행 스타일 유지; DI 주입 전환은 별개 과제).
- 마이그레이션 완료 후 `ModulePath.Domains`/`ModulePath.Datas` 는 엄브렐라 case(`Domain`, `Data`)만 남기고 축소, `Networks` 는 `Foundations` → `TokenKit`/`APIHeaderKit` 교체.

---

## 8. 점진적 마이그레이션 계획 (모든 단계 빌드 그린 유지)

각 단계 = 독립 커밋(들) = 롤백 단위(revert 1회). Pilot 은 소스 이동 규모가 가장 작고 타 feature 결합이 낮은 **Notification** 을 권장.

| 단계 | 내용 | 그린 유지 방법 | 커밋 |
|---|---|---|---|
| **0. 사전 스캔·베이스라인** | ① feature 간 타입 공유 매핑(각 feature 폴더의 타입이 타 feature 폴더에서 참조되는지 — 임시 모듈 분리 컴파일 or grep), ② 빌드타임 베이스라인 측정(§9), ③ CommonDomain 수용 목록 확정 | 코드 무변경 | docs 1 |
| **1. 스캐폴드 준비** | `DomainFeatureModule`/`DataFeatureModule` enum + Path/TargetDependency 접근자 추가, `configureFeature` 에 `hasTests` 옵션 | 헬퍼 추가만, 기존 호출부 무변경 | 1 |
| **2. Foundations 분할** | `TokenKit`/`APIHeaderKit` 신설·소스 이동 → `Foundations` 는 `@_exported import TokenKit/APIHeaderKit` 셸로 전환(소비자 12곳 무변경 그린) → 소비자 import 순차 교체 → `Foundations` 삭제 | 셸 경유 2단 전환 | 3 |
| **3. Pilot: Notification** | `Domain/Notification`(4타깃)·`Data/Notification` 신설, Entity·Interface·UseCase·API·Model·Service·Repository 의 Notification 폴더 이동. 같은 커밋에서 `Presentation/Notification` 의존을 `.Domain(.Notification)` 으로, DiRegister import 교체, 두 엄브렐라 재노출에 신모듈 추가 | feature 1개 원자 전환 (소비자가 Presentation/Notification·App 뿐이라 폐쇄적) | 2 (Domain/Data 분리) |
| **4. Pilot 검증 게이트** | 전 스킴 빌드·테스트, tuist graph 순환 0, 증분빌드 체감 측정. 문제 시 여기서 설계 보정 | — | 0 |
| **5. 배치 1: Auth(+OAuth), Profile, Search** | 3단계 반복. Auth 는 OAuth(Apple/Google/Kakao) 흡수 + googleSignIn 을 AuthData 로 국소화 | feature 당 커밋 분리 | 3~6 |
| **6. 배치 2: Home, Battle, Comment, Perspective** | 상호 참조 개연성 높은 묶음 — 0단계 매핑 기반으로 공유 타입을 CommonDomainInterface 로 먼저 승격 후 이동 | 승격 커밋 → 이동 커밋 | 4~8 |
| **7. Common + 구모듈 해체** | `Domain/Common`·`Data/Common` 신설(횡단 이동, mixpanel/googleMobileAds 국소화), 잔여물 0 확인 후 `Entity`/`UseCase`/`DomainInterface`/`API`/`Model`/`Service`/`Repository`/`DomainTesting`/`DataTesting` xcodeproj 삭제, 엄브렐라 재노출 최종본, `ModulePath` 축소 | 구모듈이 빈 껍데기가 된 뒤 삭제 | 2~3 |
| **8. 최종 검증** | §10 성공 기준 전체 + 빌드타임 after 측정·기록 | — | docs 1 |

- 병행 기간 전략: 5~6단계 동안 미전환 feature 는 구 레이어 모듈에 그대로 → 구/신 접근자가 공존하므로 develop 에 단계별 머지 가능, 장수 브랜치 불필요.
- 롤백: 각 feature 전환은 소스 이동+Project.swift 참조 교체가 한 커밋군에 갇히므로 revert 로 복원 가능. Derived/xcodeproj 는 `tuist generate` 재실행으로 재생성.

---

## 9. 리스크와 완화

| 리스크 | 내용 | 완화 |
|---|---|---|
| **feature 간 숨은 타입 공유** | 단일 모듈에선 import 없이 통용되던 타입이 분리 후 컴파일 에러/순환으로 표출 | 0단계 스캔으로 사전 매핑. 원칙: 소유 feature Interface 에 두고 단방향 참조, 진짜 공용만 CommonDomainInterface 승격. CommonDomain 비대화가 감지되면(승격 비율 >20%) 토폴로지 재검토 |
| **빌드타임 악화 가능성** | 타깃 수 증가로 clean build·링크 시간 증가 가능 (증분은 개선 기대) | before/after 측정을 게이트로: `xcodebuild build -scheme Picke-Stage -destination 'generic/platform=iOS Simulator' -showBuildTimingSummary` clean 3회 평균 + "단일 UseCase 1줄 수정 후 증분" 시나리오. Pilot(4단계)에서 악화 시 중단·보정 |
| **xcodeproj/스킴/Derived 폭증** | 22 xcodeproj, Domain 37타깃 — generate 시간·Xcode 네비게이터 부담 | `configureFeature` 에 hasTests/hasTesting 옵션(§7.1)으로 빈 타깃 억제, 스킴은 hidden 기본, 측정: `time tuist generate` before/after |
| **WeaveDI 등록 누락** | DiRegister 의 29개 등록이 import 교체 과정에서 실체 누락되면 **런타임에만** 발견 | feature 전환 커밋마다 앱 부팅 스모크(로그인→홈) 확인, DiRegister 는 엄브렐라(Data) import 로 전환해 이동에 둔감하게 유지 |
| **`@_exported` 잔재로 경계 침식** | 엄브렐라를 Presentation 이 몰래 참조하면 재편 효과 소멸 | §4.3 규칙 + 완료 기준에 "Presentation→엄브렐라 에지 0" 포함, tuist graph 로 기계 검증 |
| **Testing 해체 리스크** | DomainTesting/DataTesting 소비자가 있으면 이동 시 파손 | 사전 grep 으로 소비자 확인 후 feature Testing 타깃으로 이동, 테스트 케이스 수 before/after 동일 확인 |

---

## 10. 성공 기준 (검증 가능)

1. **빌드 그린**: `tuist generate` 후 Stage·Prod 전 스킴 빌드 성공, 기존 테스트 전부 통과(케이스 수 감소 없음).
2. **토폴로지**: `tuist graph` 기준 ① 순환 0, ② Presentation→Data 에지 0, ③ `<F>Domain`/`<F>Data` 구현 타깃 간 feature 교차 에지 0, ④ Presentation feature→엄브렐라 에지 0.
3. **구조 완료**: 구 레이어 모듈 9개(Entity, UseCase, DomainInterface, DomainTesting, API, Model, Service, Repository, DataTesting) 및 `Foundations` 삭제됨. `TokenKit`/`APIHeaderKit` 대체 완료.
4. **SPM 국소화**: mixpanel·googleMobileAds 는 CommonDomain(+CommonData), googleSignIn 은 AuthData 에만 연결.
5. **빌드타임 기록**: clean/증분 before·after 가 본 문서 부록에 기록되고, "단일 feature 수정 증분 빌드"가 before 대비 악화되지 않음(개선 목표).
6. **런타임 스모크**: 스플래시→로그인→홈→배틀→알림 플로우에서 DI resolve 실패(폴백 InMemoryTokenProvider 사용 포함) 0건.

---

## 부록 A. 0단계 사전 스캔 결과 (실행용 확정 결정)

> Domain+Data 전체 타입 351개 중 feature 교차 공유 = 약 12~13개(넓게 ~18개) → **≈3.7~5%** (20% 기준 크게 하회, 토폴로지 재검토 불필요). feature 경계 건강.

### A.1 재배치(re-home) 필수 — Entity `Home/` 는 메가폴더
폴더 위치 ≠ 소유권. 모듈 분리 시 아래로 이동:
- `Entity/Sources/Home/Battle/**` → **Battle** 소유 (BattleDetail, BattleInfo, BattleOption, PreVoteResult, RecommendedBattle, BattleVoteStats, BattleScenario …)
- `Entity/Sources/Home/Comment/Item/**` → **Comment** (Comment, CommentItem, CommentLikeResult …)
- `Entity/Sources/Home/Comment/Perspective/**`, `.../PerspectiveComment/**` → **Perspective** (BattlePerspective*, PerspectiveComment*)
- `Entity/Sources/Home/{Section,Core,Scenario,Explore}/**` → **Home** (HeroBattle, HotBattle, BestBattle, NewBattle, QuizQuestion, VoteQuestion, HomeBundle, BattleTag …)

### A.2 CommonDomainInterface 승격 확정 목록 (순환 차단용)
- **BattlePerspective 계열 5개**: BattlePerspective, BattlePerspectivePage, BattlePerspectiveSort, BattlePerspectiveOption, BattlePerspectiveUser (Battle↔Perspective 순환 차단)
- **CommentLikeResult, CommentError 2개** (Comment↔Perspective 준순환 차단)
- BattleTag: Home 소유가 자연스러우나 Battle 도 소비 → Common 최소 승격 또는 Home 잔류+Battle 이 Home Interface 참조 중 택1(배치2에서 확정)

### A.3 Auth+OAuth 병합 확정
AuthTokens, UserSession, LoginEntity, SocialType, AuthError 5개를 Auth·OAuth 가 양방향 공유 → **`AuthDomain` 단일 모듈로 병합**(§3.1대로), 승격 대신 병합이 단순. googleSignIn 은 AuthData 로 국소화.

### A.4 이름 충돌 처리
`BattleStep` 이 2곳 정의: `Entity/Home/Battle/Detail/BattleStep.swift`(Battle enum) + `UseCase/Analytics/Events/BattleStepData.swift`(Analytics enum). Battle 모듈과 Analytics(Common) 모듈 동시 import 시 충돌 → **Analytics 쪽을 `AnalyticsBattleStep` 으로 리네임**.

### A.5 고립(자기완결) feature — 이동 단순, 승격 불필요
Notification, Search, Profile, Device, AppUpdate, Deeplink, Share, Ad, Analytics 는 Domain/Data 레이어 내 타 feature 엔티티 미참조. → **Notification 파일럿 선정이 타당함**(폐쇄적, 소비자 Presentation/Notification·App 뿐).

### A.6 순환 위험 쌍 (배치2 순서 근거)
Battle↔Perspective(최고, A.2 승격으로 해소) > Comment↔Perspective(준순환, A.2) > Auth↔OAuth(A.3 병합). Home↔Battle 은 순환 아님(BattleTag 단방향). → 배치2는 **승격 커밋 먼저 → feature 이동 커밋** 순서.
