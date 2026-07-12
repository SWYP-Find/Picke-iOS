//
//  PickeModal.swift
//  DesignSystem
//
//  TCA @Presents 스토어 기반 커스텀 바텀시트 오버레이.
//  예: .pickeModal($store.scope(state: \.termsAgreement, action: \.termsAgreement)) { TermsAgreementSheetView(store: $0) }
//

import SwiftUI

import ComposableArchitecture

public extension View {
  /// 하단에서 슬라이드업 되는 커스텀 모달(바텀시트) 오버레이.
  /// - Parameters:
  ///   - store: `@Presents` 스코프 바인딩 (nil 이면 미표시).
  ///   - content: 표시할 모달 뷰 (스코프된 스토어를 받음).
  func pickeModal<State, Action>(
    _ store: Binding<Store<State, Action>?>,
    @ViewBuilder content: @escaping (Store<State, Action>) -> some View
  ) -> some View {
    overlay {
      if let modalStore = store.wrappedValue {
        content(modalStore)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.wrappedValue != nil)
  }
}
