//
//  View+measureSize.swift
//  PickeCoreUI
//

import SwiftUI

public extension View {
  /// 뷰가 실제로 그려진 크기를 알려준다.
  ///
  /// 레이아웃에는 영향을 주지 않는다 — 배경에 깔린 `GeometryReader` 가 크기만
  /// 읽어 `PreferenceKey` 로 올려보낸다. 크기가 바뀔 때마다 다시 불린다.
  ///
  /// ```swift
  /// Text(title)
  ///   .measureSize { titleSize = $0 }
  /// ```
  ///
  /// SwiftUIX 의 `measureSize(_:)` 와 같은 구현이다. 라이브러리 전체를 의존성으로
  /// 들이는 대신 필요한 한 조각만 옮겨 왔다. (SwiftUIX, MIT License)
  func measureSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { proxy in
        Color.clear.preference(key: SizePreferenceKey.self, value: proxy.size)
      }
    )
    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
  }
}

private struct SizePreferenceKey: PreferenceKey {
  static let defaultValue = CGSize.zero

  static func reduce(value _: inout CGSize, nextValue _: () -> CGSize) {}
}
