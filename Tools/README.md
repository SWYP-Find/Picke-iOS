# Tools

## TokenGenerator.swift

Tokens Studio for Figma 가 export 한 `Mode 1.tokens.json` 을 Swift 토큰으로 변환합니다.

### 입력
- `SWYP-Find/design-tokens` 레포의 `Mode 1.tokens.json` (단일 소스)
- 워크플로우 실행 시 raw URL 로 받아 로컬 `Projects/Shared/DesignSystem/Resources/Mode 1.tokens.json` 에 임시 저장 (커밋되지 않음 — `.gitignore` 처리)

### 출력 (덮어쓰기)
- `Projects/Shared/DesignSystem/Sources/Color/ShapeStyle+.swift` — 색 토큰 (brand / semantic / status / bg)
- `Projects/Shared/DesignSystem/Sources/Extension/CGFloat/CGFloat+Radius+.swift` — radius (`.none` / `.default` / `.full`)
- `Projects/Shared/DesignSystem/Sources/Extension/CGFloat/CGFloat+Spacing+.swift` — spacing (`.s0` ~ `.s96`)
- `Projects/Shared/DesignSystem/Sources/UI/Token/ComponentToken.swift` — 컴포넌트 토큰 (`ComponentToken.Button.Primary.Background.default` 등)

### 자동화 (권장 경로)
디자이너가 `SWYP-Find/design-tokens` 레포의 `Mode 1.tokens.json` 을 push 하면 다음이 자동으로 진행됩니다:

```
design-tokens main 브랜치에 푸시
  ↓ notify-ios.yml
  ↓ repository_dispatch(design-tokens-updated)
Picke-iOS sync-design-tokens.yml
  ├ raw URL 로 JSON 다운로드
  ├ swift Tools/TokenGenerator.swift
  └ develop 브랜치에 4개 출력 파일 직접 commit + push
```

수동 트리거가 필요할 때:
```
gh workflow run sync-design-tokens.yml --repo SWYP-Find/Picke-iOS
```

### 로컬 실행 (선택)
JSON 을 로컬에 두고 코드젠 결과를 미리 확인하고 싶을 때만:
```
curl -fsSL https://raw.githubusercontent.com/SWYP-Find/design-tokens/main/Mode%201.tokens.json \
  -o "Projects/Shared/DesignSystem/Resources/Mode 1.tokens.json"
swift Tools/TokenGenerator.swift
```

### 사용 예
```swift
Text("Hello")
  .foregroundStyle(.primary500)
  .background(.bgDefault)

VStack(spacing: .s16) {
  RoundedRectangle(cornerRadius: .default)
}

Button("입장 선택하기") { }
  .ctaButtonStyle(.primary, size: .large)  // ComponentToken.Button.Primary.* 참조
```

⚠️ 출력 4개 파일은 자동 생성됩니다. **직접 수정 금지** — 변경하려면 디자이너의 Tokens Studio 토큰 자체를 수정해야 합니다.
