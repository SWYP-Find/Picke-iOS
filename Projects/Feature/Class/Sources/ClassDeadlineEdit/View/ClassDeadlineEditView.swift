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

  public init(store: StoreOf<ClassDeadlineEditFeature>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        headerSection()
        deadlineSection()
        saveButton
      }
      .padding(.horizontal, 16)
      .padding(.top, 24)
      .padding(.bottom, 40)
    }
    .scrollIndicators(.hidden)
    .background(.beige50)
    .environment(\.timeZone, AppDateFormat.timeZone)
    .environment(\.calendar, AppDateFormat.calendar)
  }
}

private extension ClassDeadlineEditView {
  @ViewBuilder
  func headerSection() -> some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text("참여 마감일 수정")
          .pretendardFont(.semiBold24)
          .foregroundStyle(.gray800)
        Text(store.room.name)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray500)
      }
      Spacer(minLength: 0)
      Button { send(.backTapped) } label: {
        Image(systemName: "xmark")
          .foregroundStyle(.gray800)
          .frame(width: 44, height: 44)
      }
      .accessibilityLabel("닫기")
      .disabled(store.isSaving)
    }
  }

  @ViewBuilder
  func deadlineSection() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Toggle("참여 마감일 설정", isOn: Binding(
        get: { store.isDeadlineEnabled },
        set: { send(.deadlineEnabledChanged($0)) }
      ))
      .pretendardFont(.semiBold15)
      .tint(.primary500)
      .disabled(store.isSaving)

      Text(store.selectedDeadlineText)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray500)

      if store.isDeadlineEnabled {
        DatePicker(
          "날짜",
          selection: $store.draftDeadline,
          in: store.minimumSelectableDate...,
          displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .disabled(store.isSaving)

        DatePicker(
          "시간",
          selection: $store.draftDeadline,
          in: store.minimumSelectableDate...,
          displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.compact)
        .disabled(store.isSaving)
      }

      if let validationMessage = store.validationMessage {
        Text(validationMessage)
          .pretendardFont(.regular13)
          .foregroundStyle(.red)
      }
      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .pretendardFont(.regular13)
          .foregroundStyle(.red)
      }
    }
  }

  var saveButton: some View {
    Button("수정하기") { send(.saveTapped) }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .disabled(!store.canSave)
  }
}
