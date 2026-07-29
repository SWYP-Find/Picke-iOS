//
//  BattleProposalView.swift
//  Profile
//

import SwiftUI

import ComposableArchitecture
import PickeDesignKit
import Entity
import BattleDomainInterface

@ViewAction(for: BattleProposalFeature.self)
public struct BattleProposalView: View {
  @Bindable public var store: StoreOf<BattleProposalFeature>
  @FocusState private var isInputFocused: Bool

  public init(store: StoreOf<BattleProposalFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "배틀 만들기")
        .foregroundStyle(.gray500)

      ScrollView {
        VStack(spacing: 16) {
          categoryField()
          topicField()
          stanceField()
          descriptionField()
          submitButton()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)
      .background(
        Color.beige200
          .onTapGesture {
            isInputFocused = false
          }
      )
    }
    .background(Color.beige200.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .customAlert($store.scope(state: \.customAlert, action: \.scope.customAlert))
  }
}

private extension BattleProposalView {
  // MARK: 공통 라벨

  @ViewBuilder
  func fieldLabel(_ text: String) -> some View {
    Text(text)
      .pretendardFont(.labelSmall)
      .foregroundStyle(.gray400)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: 카테고리

  @ViewBuilder
  func categoryField() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      fieldLabel("카테고리 *")

      HStack(spacing: 0) {
        ForEach(Array(BattleProposalCategory.allCases.enumerated()), id: \.element.id) { index, category in
          let isSelected = store.selectedCategory == category
          Button {
            send(.categorySelected(category))
          } label: {
            Text(category.title)
              .pretendardFont(.labelMedium)
              .foregroundStyle(isSelected ? .beige50 : .gray300)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 8)
              .background(isSelected ? .primary500 : .beige50)
              .overlay(alignment: .trailing) {
                if !isSelected, index < BattleProposalCategory.allCases.count - 1 {
                  Rectangle().fill(.beige600).frame(width: 1)
                }
              }
          }
          .buttonStyle(.plain)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault)
          .stroke(.beige600, lineWidth: 1)
      )
    }
  }

  // MARK: 주제

  @ViewBuilder
  func topicField() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      fieldLabel("주제 *")
      inputField(text: $store.topic, placeholder: "논쟁이 될만한 주제를 한 줄로 써주세요")
    }
  }

  // MARK: 양측 입장

  @ViewBuilder
  func stanceField() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      fieldLabel("양측 입장 *")

      HStack(spacing: 8) {
        Text("A")
          .pretendardFont(.headingSmall)
          .foregroundStyle(.primary500)
          .frame(width: 20)
        inputField(text: $store.positionA, placeholder: "첫 번째 입장을 입력하세요")
      }

      HStack(spacing: 8) {
        Text("B")
          .pretendardFont(.headingSmall)
          .foregroundStyle(.neutral900)
          .frame(width: 20)
        inputField(text: $store.positionB, placeholder: "두 번째 입장을 입력하세요")
      }
    }
  }

  // MARK: 입력 필드 (한 줄)

  @ViewBuilder
  func inputField(text: Binding<String>, placeholder: String) -> some View {
    ZStack(alignment: .leading) {
      if text.wrappedValue.isEmpty {
        Text(placeholder)
          .pretendardFont(.medium13)
          .foregroundStyle(.gray300)
      }
      TextField("", text: text)
        .pretendardFont(.medium13)
        .foregroundStyle(.gray800)
        .focused($isInputFocused)
    }
    .padding(.leading, 8)
    .frame(height: 44)
    .frame(maxWidth: .infinity)
    .roundedBackground(.beige50)
    .overlay(
      RoundedRectangle(cornerRadius: .radiusDefault)
        .stroke(.beige600, lineWidth: 1)
    )
  }

  // MARK: 부가 설명

  @ViewBuilder
  func descriptionField() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      fieldLabel("부가 설명 (선택)")

      VStack(alignment: .trailing, spacing: 4) {
        ZStack(alignment: .topLeading) {
          if store.description.isEmpty {
            Text("이 주제를 제안하는 이유나 배경을 자유롭게 써주세요")
              .pretendardFont(.regular13)
              .foregroundStyle(.gray300)
              .padding(.top, 8)
              .padding(.leading, 4)
          }
          TextEditor(text: $store.description)
            .pretendardFont(.regular13)
            .foregroundStyle(.gray800)
            .scrollContentBackground(.hidden)
            .frame(height: 60)
            .focused($isInputFocused)
        }

        Text("\(store.description.count)/200")
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.gray400)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .frame(maxWidth: .infinity)
      .roundedBackground(.beige50)
      .overlay(
        RoundedRectangle(cornerRadius: .radiusDefault)
          .stroke(.beige600, lineWidth: 1)
      )
    }
  }

  // MARK: 제안하기

  @ViewBuilder
  func submitButton() -> some View {
    Button {
      send(.submitTapped)
    } label: {
      Text("제안하기 (-30P)")
        .pretendardFont(.labelMedium)
        .foregroundStyle(.beige50)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(
          store.isSubmitEnabled ? .primary500 : .primary200,
          in: RoundedRectangle(cornerRadius: .radiusDefault)
        )
    }
    .buttonStyle(.plain)
    .disabled(!store.isSubmitEnabled)
    .padding(.top, 8)
  }
}
