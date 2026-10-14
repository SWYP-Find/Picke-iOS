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
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  public init(store: StoreOf<ClassDeadlineEditFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        pickerSection()
          .padding(.horizontal, 16)
          .padding(.top, 8)
      }
      .scrollIndicators(.hidden)
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      footerSection()
    }
    .background(.white)
    .environment(\.timeZone, AppDateFormat.timeZone)
    .environment(\.calendar, AppDateFormat.calendar)
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
          .frame(height: 216)
      }
    }
  }

  var deadlinePicker: some View {
    DatePicker(
      "참여 마감일",
      selection: $store.draftDeadline,
      in: store.minimumSelectableDate...,
      displayedComponents: [.date, .hourAndMinute]
    )
    .datePickerStyle(.wheel)
    .labelsHidden()
    .frame(maxWidth: .infinity)
    .frame(height: 216)
    .disabled(store.isSaving)
  }

  var enableDeadlineButton: some View {
    Button("마감일 설정하기") { send(.deadlineEnabledChanged(true)) }
      .pretendardFont(.semiBold15)
      .foregroundStyle(.primary500)
      .frame(minHeight: 44)
      .disabled(store.isSaving)
  }

  @ViewBuilder
  func footerSection() -> some View {
    VStack(spacing: 8) {
      if let message = store.errorMessage ?? store.validationMessage {
        Text(message)
          .pretendardFont(.regular13)
          .foregroundStyle(.red)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityIdentifier("class-deadline-error")
      }
      saveButton
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 8)
    .background(.white)
  }

  var saveButton: some View {
    Button("수정하기") { send(.saveTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .accessibilityIdentifier("class-deadline-save")
      .disabled(!store.canSave)
  }
}
