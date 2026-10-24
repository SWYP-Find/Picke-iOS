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
        noDeadlineMessage
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

  var noDeadlineMessage: some View {
    Text("마감일이 없는 클래스는 마감일을 연장할 수 없어요.")
      .pretendardFont(.semiBold15)
      .foregroundStyle(.neutral500)
  }

  var saveButton: some View {
    Button("수정하기") { send(.saveTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .accessibilityIdentifier("class-deadline-save")
      .disabled(!store.canSave || isAdjusting)
  }
}
