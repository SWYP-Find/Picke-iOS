//
//  ClassDeadlineEditView.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassDeadlineEditFeature.self)
public struct ClassDeadlineEditView: View {
  @Bindable public var store: StoreOf<ClassDeadlineEditFeature>

  @State private var isAdjusting = false

  public init(store: StoreOf<ClassDeadlineEditFeature>) {
    self.store = store
  }

  public var body: some View {
    ClassDeadlinePanelContent(message: store.errorMessage ?? store.validationMessage) {
      pickerSection()
    } button: {
      saveButton
    }
  }
}

private extension ClassDeadlineEditView {
  @ViewBuilder
  func pickerSection() -> some View {
    VStack(spacing: 0) {
      if store.isDeadlineEnabled {
        deadlinePicker
      } else {
        enableDeadlineButton
          .frame(height: 174)
      }
    }
  }

  var deadlinePicker: some View {
    ClassDeadlinePicker(
      selection: $store.draftDeadline,
      minimumDate: store.minimumSelectableDate,
      isAdjusting: $isAdjusting
    )
    .disabled(store.isSaving)
  }

  var enableDeadlineButton: some View {
    Button("마감일 설정하기") { send(.deadlineEnabledChanged(true)) }
      .pretendardFont(.semiBold15)
      .foregroundStyle(.primary500)
      .frame(minHeight: 44)
      .disabled(store.isSaving)
  }

  var saveButton: some View {
    Button("수정하기") { send(.saveTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .accessibilityIdentifier("class-deadline-save")
      .disabled(!store.canSave || isAdjusting)
  }
}
