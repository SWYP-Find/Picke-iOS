---
paths:
  - "Projects/**"
---

# iOS 경로 규칙

상세 원본: `AGENTS.md` "(필수)" 절, `docs/agent/tca-patterns.md`, `docs/agent/swiftui-patterns.md`

## Hard

- Feature는 `{기능}DomainInterface`의 UseCase만 쓴다. Repository · Domain 구현 · `PickeNetwork` · `API` · `APIEndpoint`를 import하거나 주입받지 않는다. (verify가 검사)
- View는 `@Bindable private var store: StoreOf<Feature>`로 Store를 갖는다.
- `body`에는 최상위 레이아웃만 두고 구역은 `extension`의 private 함수 · 프로퍼티로 나눈다. 자식 2개 이상이면 `@ViewBuilder private func`, 단일 뷰면 `private var`.
- 화면에 보이는 문구 · 값 계산은 State computed property로 둔다. `body` 안에서 계산하지 않는다.
- 화면 전용 모델 · Item · Tab 같은 타입은 Reducer 안에 중첩하지 않고 같은 모듈 `Model/` 폴더의 최상위 타입으로 둔다.
- 폰트는 Pretendard 토큰, 색은 디자인 토큰을 쓴다. `.font(.system(...))` · 원시 hex를 새로 쓰지 않는다.
- 화면 전환은 App의 Coordinator가 한다. 자식 Feature는 `delegate`로 알린다. Coordinator의 `@Reducer public enum XScreen` 구조를 바꾸지 않는다.
- `try!` · 강제 언래핑을 쓰지 않는다. (`try!`는 verify가 검사)
- `.xcodeproj` · `.xcworkspace`는 직접 고치지 않는다. 파일 · 모듈을 추가하면 `./make generate --no-open`.

## Soft (기존 코드가 다르면 기존 코드를 따른다)

- 비동기 결과는 `Result { try await }` + 단일 `Response` inner 액션으로 받는다.
- 재생 · 타이머 · 폴링 effect는 `CancelID`로 취소 가능하게 두고 화면 이탈 때 취소한다.
- Reducer 테스트는 Swift Testing + `TestStore`로 쓴다.
