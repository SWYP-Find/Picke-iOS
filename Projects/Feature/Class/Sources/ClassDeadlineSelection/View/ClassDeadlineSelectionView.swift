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
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  public init(store: StoreOf<ClassDeadlineSelectionFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      pickerScroll
    }
    .safeAreaInset(edge: .bottom, spacing: 0) { footerSection() }
    .background(.white)
  }
}

private extension ClassDeadlineSelectionView {
  var pickerScroll: some View {
    ScrollView {
      ClassDeadlinePicker(
        selection: $store.draftDeadline,
        minimumDate: store.minimumSelectableDate
      )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  func footerSection() -> some View {
    VStack(spacing: 8) {
      if let message = store.validationMessage {
        Text(message)
          .pretendardFont(.regular13)
          .foregroundStyle(.red)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      confirmButton
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 8)
    .background(.white)
  }

  var confirmButton: some View {
    Button(store.buttonTitle) { send(.confirmTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .accessibilityIdentifier("class-deadline-confirm")
      .disabled(!store.canConfirm)
  }
}
