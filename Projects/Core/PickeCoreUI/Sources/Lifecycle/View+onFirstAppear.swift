//
//  View+onFirstAppear.swift
//  PickeCoreUI
//

import SwiftUI

public extension View {
  /// 뷰가 **처음** 화면에 올라올 때 한 번만 실행한다.
  ///
  /// `onAppear` 는 탭 전환·네비게이션 복귀·리스트 셀 재사용마다 다시 불린다.
  /// 초기 로드처럼 한 번이면 충분한 작업은 매 호출마다 `if !didLoad` 가드를
  /// 손으로 다는 대신 이 모디파이어를 쓴다.
  ///
  /// ```swift
  /// .onFirstAppear { send(.onAppear) }
  /// ```
  ///
  /// SwiftUIX 의 `onAppearOnce` 와 같은 구현이다. 라이브러리 전체를 의존성으로
  /// 들이는 대신 필요한 한 조각만 옮겨 왔다. (SwiftUIX, MIT License)
  func onFirstAppear(_ action: @escaping () -> Void) -> some View {
    modifier(OnFirstAppearModifier(action: action))
  }
}

private struct OnFirstAppearModifier: ViewModifier {
  let action: () -> Void

  @State private var didAppear = false

  func body(content: Content) -> some View {
    content.onAppear {
      guard !didAppear else { return }
      didAppear = true
      action()
    }
  }
}
