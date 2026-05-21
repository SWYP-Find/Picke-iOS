//
//  CustomAlertModifiers.swift
//  DesignSystem
//

import ComposableArchitecture
import SwiftUI

public extension View {
  func customAlert(
    _ store: Binding<Store<CustomAlertState<CustomAlertAction>, CustomAlertAction>?>
  ) -> some View {
    overlay {
      if let alertStore = store.wrappedValue {
        let alertState = alertStore.withState { $0 }
        CustomConfirmationPopup(
          title: alertState.title,
          message: alertState.message,
          confirmTitle: alertState.confirmTitle,
          cancelTitle: alertState.cancelTitle,
          isDestructive: alertState.isDestructive,
          style: alertState.style,
          onConfirm: { alertStore.send(.confirmTapped) },
          onCancel: { alertStore.send(.cancelTapped) }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: alertState.title.isEmpty == false)
      }
    }
  }
}
