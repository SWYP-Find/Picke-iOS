//
//  PickeModal.swift
//  DesignSystem
//

import ComposableArchitecture
import PickeDesignKit
import SwiftUI

public extension View {
  /// 하단에서 슬라이드업 되는 커스텀 모달(바텀시트) 오버레이.
  /// 딤은 제자리에서 페이드되고, 시트만 아래에서 올라온다.
  /// - Parameters:
  ///   - store: `@Presents` 스코프 바인딩 (nil 이면 미표시).
  ///   - dimOpacity: 딤 배경 불투명도.
  ///   - content: 표시할 모달 뷰 (스코프된 스토어를 받음).
  func pickeModal<State, Action>(
    _ store: Binding<Store<State, Action>?>,
    dimOpacity: Double = 0.4,
    @ViewBuilder content: @escaping (Store<State, Action>) -> some View
  ) -> some View {
    overlay {
      ZStack {
        if store.wrappedValue != nil {
          Color.black.opacity(dimOpacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
        if let modalStore = store.wrappedValue {
          content(modalStore)
            .transition(.move(edge: .bottom))
        }
      }
    }
    .animation(
      .spring(
        response: 0.36,
        dampingFraction: 0.86
      ),
      value: store.wrappedValue != nil
    )
  }
}
