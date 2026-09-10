//
//  LazyView.swift
//  PickeCoreUI
//

import SwiftUI

/// 자식 뷰의 생성을 실제로 그려질 때까지 미루는 래퍼.
///
/// `TabView` 는 `ForEach` 로 모든 탭의 콘텐츠를 한 번에 만들기 때문에,
/// 선택되지 않은 탭의 뷰와 그 뷰가 붙잡는 값(스토어 스코프 등)까지 즉시 생성된다.
/// 이 래퍼를 씌우면 `body` 가 평가되는 시점 — 즉 해당 탭이 처음 화면에 올라올 때 —
/// 까지 생성이 지연된다.
///
/// ```swift
/// LazyView {
///   HomeCoordinatorView(store: store.scope(state: \.homeState, action: \.home))
/// }
/// ```
///
/// SwiftUIX 의 `LazyView` 와 같은 구현이다. 라이브러리 전체를 의존성으로
/// 들이는 대신 필요한 이 한 조각만 옮겨 왔다. (SwiftUIX, MIT License)
public struct LazyView<Content: View>: View {
  private let content: () -> Content

  public init(@ViewBuilder _ content: @escaping () -> Content) {
    self.content = content
  }

  public var body: Content {
    content()
  }
}
