# Tools

## TokenGenerator.swift

Tokens Studio for Figma 가 export 한 `Mode 1.tokens.json` 을 Swift 토큰으로 변환합니다.

### 입력
- `Projects/Shared/DesignSystem/Resources/Mode 1.tokens.json`

### 출력 (덮어쓰기)
- `Projects/Shared/DesignSystem/Sources/Color/ShapeStyle+.swift` — 컬러 (brand / semantic / status / bg)
- `Projects/Shared/DesignSystem/Sources/Extension/CGFloat/CGFloat+Radius+.swift` — radius (`.none` / `.default` / `.full`)
- `Projects/Shared/DesignSystem/Sources/Extension/CGFloat/CGFloat+Spacing+.swift` — spacing (`.s0` ~ `.s96`)

### 실행
```
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
```

### 디자이너 핸드오프 흐름
1. 디자이너가 Tokens Studio → `Mode 1.tokens.json` export
2. 위 경로에 덮어쓰기
3. `swift Tools/TokenGenerator.swift` 실행
4. 빌드 검증 → 커밋

⚠️ 출력 3개 파일은 자동 생성됩니다. 직접 수정하지 마세요.
