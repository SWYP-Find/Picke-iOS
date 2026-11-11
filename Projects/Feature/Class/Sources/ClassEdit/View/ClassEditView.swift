//
//  ClassEditView.swift
//  Class
//
//  Created by Picke on 11/11/26.
//

import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import SwiftUI

/// Android `ClassEditScreen` — 클래스 명 + 참여 마감일 + 저장 버튼.
@ViewAction(for: ClassEditFeature.self)
public struct ClassEditView: View {
  @Bindable public var store: StoreOf<ClassEditFeature>
  @FocusState private var isNameFocused: Bool

  public init(store: StoreOf<ClassEditFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar
      formScroll
      saveButton
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassEditView {
  var navigationBar: some View {
    PickeNavigationBar(
      onBack: { send(.backTapped) },
      centerTitle: "클래스 수정"
    )
    .foregroundStyle(.gray500)
  }

  var formScroll: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        Text("클래스 정보를 수정해 주세요")
          .pretendardFont(.semiBold24)
          .foregroundStyle(.gray800)
          .frame(maxWidth: .infinity, alignment: .leading)

        nameSection()
        deadlineSection()

        if let message = store.errorMessage {
          Text(message)
            .pretendardFont(.regular13)
            .foregroundStyle(.red)
        }
      }
      .padding(16)
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
  }

  @ViewBuilder
  func nameSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 4) {
        sectionLabel("클래스 명")
        Text("*")
          .pretendardFont(.semiBold15)
          .foregroundStyle(.primary500)
      }

      TextField(
        "",
        text: $store.name,
        prompt: Text("ex) 2학년 3반 1학기 토론")
          .font(
            .pretendardFontFamily(
              family: .Medium,
              size: 13
            )
          )
          .foregroundStyle(.gray300)
      )
      .pickeTextField()
      .focused($isNameFocused)
      .disabled(store.isSaving)
      .accessibilityIdentifier("class-edit-name")

      if store.isNameInvalid {
        Text("클래스 명을 입력해 주세요")
          .pretendardFont(.regular13)
          .foregroundStyle(.red)
      }
    }
  }

  @ViewBuilder
  func deadlineSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("참여 마감일")
      deadlineField
      if let message = store.deadlineValidationMessage {
        Text(message)
          .pretendardFont(.regular13)
          .foregroundStyle(.red)
      }
    }
  }

  var deadlineField: some View {
    Button {
      isNameFocused = false
      send(.deadlineFieldTapped)
    } label: {
      Text(store.deadlineText)
        .pretendardFont(.labelMedium)
        .foregroundStyle(store.hasDeadline ? .gray800 : .gray300)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .pickeCard(.beige50, border: .beige600)
    }
    .buttonStyle(.plain)
    .disabled(!store.hasDeadline || store.isSaving)
    .accessibilityIdentifier("class-edit-deadline")
  }

  func sectionLabel(_ title: String) -> some View {
    Text(title)
      .pretendardFont(.semiBold15)
      .foregroundStyle(.gray800)
      .frame(minHeight: 23, alignment: .leading)
  }

  var saveButton: some View {
    Button {
      isNameFocused = false
      send(.saveTapped)
    } label: {
      Text("클래스 수정하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canSave)
    .accessibilityIdentifier("class-edit-save")
  }
}
