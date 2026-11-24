//
//  ClassDeadlineSelectionView.swift
//  Class
//
//  Created by Picke on 10/15/26.
//

import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassDeadlineSelectionFeature.self)
public struct ClassDeadlineSelectionView: View {
  @Bindable public var store: StoreOf<ClassDeadlineSelectionFeature>

  @State private var isAdjusting = false

  public init(store: StoreOf<ClassDeadlineSelectionFeature>) {
    self.store = store
  }

  public var body: some View {
    ClassDeadlinePanelContent(message: store.validationMessage) {
      ClassDeadlinePicker(
        selection: $store.draftDeadline,
        minimumDate: store.minimumSelectableDate,
        isAdjusting: $isAdjusting
      )
    } button: {
      confirmButton
    }
  }
}

private extension ClassDeadlineSelectionView {
  var confirmButton: some View {
    Button(store.buttonTitle) { send(.confirmTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .accessibilityIdentifier("class-deadline-confirm")
      .disabled(!store.canConfirm || isAdjusting)
  }
}
