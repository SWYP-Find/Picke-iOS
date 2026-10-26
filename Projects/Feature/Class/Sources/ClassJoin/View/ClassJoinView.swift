//
//  ClassJoinView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassJoinFeature.self)
public struct ClassJoinView: View {
  @Bindable public var store: StoreOf<ClassJoinFeature>
  @FocusState private var isCodeFocused: Bool

  public init(store: StoreOf<ClassJoinFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: store.navigationCenterTitle,
        leadingTitle: store.navigationLeadingTitle,
        leadingSpacing: 12
      )
      .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: store.mode == .code ? 20 : 24) {
          titleSection()
          switch store.mode {
          case .code:
            codeSection()
          case .nickname, .ownerName:
            nicknameSection()
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)

      bottomAction
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    .ignoresSafeArea(.container, edges: store.mode == .code ? .bottom : [])
    .screenBackground(.surfaceBeigeDefault)
    .hidesSystemBars()
  }
}

private extension ClassJoinView {
  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: store.mode == .code ? 6 : 8) {
      Text(store.mode == .code ? "공유받은 코드로\n클래스에 참여하세요" : "이름을 입력해주세요")
        .pretendardFont(.semiBold24)
        .lineSpacing(store.mode == .code ? 7 : 2.4)
        .foregroundStyle(.gray800)

      Text(store.mode == .code
        ? "전달받은 6자리 코드를 입력해 주세요."
        : "이 클래스에서만 보이는 이름이에요.\n입장 후에도 수정할 수 있어요.")
        .pretendardFont(.bodyMedium)
        .lineSpacing(4)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func codeSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      ZStack {
        HStack(spacing: 14) {
          ForEach(0..<6, id: \.self) { index in
            Text(store.codeCharacters[index])
              .pretendardFont(.headingMedium)
              .foregroundStyle(.gray800)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(.bgSubtle)
              .overlay {
                RoundedRectangle(cornerRadius: 2)
                  .strokeBorder(codeBorderColor(at: index), lineWidth: 1)
              }
          }
        }

        TextField("", text: $store.joinCode)
          .textInputAutocapitalization(.characters)
          .autocorrectionDisabled()
          .keyboardType(.asciiCapable)
          .textContentType(.oneTimeCode)
          .focused($isCodeFocused)
          .accessibilityLabel("참여 코드, 6자리")
          .foregroundStyle(.clear)
          .tint(.clear)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(height: 50)

      if let message = store.errorMessage {
        errorLabel(message)
      }
    }
  }

  func codeBorderColor(at index: Int) -> Color {
    if store.errorMessage != nil { return .borderErrorDefault }
    if isCodeFocused && index == min(store.joinCode.count, 5) { return .secondary500 }
    return .gray50
  }

  @ViewBuilder
  func nicknameSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      nicknameInput

      HStack(alignment: .top, spacing: 12) {
        if let message = store.nicknameValidationMessage {
          errorLabel(message)
        }
        Spacer(minLength: 0)
        Text("\(store.nicknameCharacterCount)/\(ClassJoinFeature.State.nicknameLimit)")
          .pretendardFont(.bodySmall)
          .foregroundStyle(.gray300)
          .accessibilityLabel("이름 \(store.nicknameCharacterCount)자, 최대 \(ClassJoinFeature.State.nicknameLimit)자")
      }

      if let message = store.errorMessage {
        errorLabel(message)
      }
    }
  }

  var nicknameInput: some View {
    TextField("", text: $store.nickname, prompt: Text(store.nicknamePlaceholder).foregroundStyle(.gray300))
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .accessibilityLabel("클래스에서 사용할 이름")
      .pickeTextField(height: 52)
      .overlay {
        if store.nicknameValidationMessage != nil {
          RoundedRectangle(cornerRadius: 2)
            .strokeBorder(.borderErrorDefault, lineWidth: 1)
        }
      }
  }

  func errorLabel(_ message: String) -> some View {
    Text(message)
      .pretendardFont(.bodySmall)
      .foregroundStyle(.errorDefault)
      .fixedSize(horizontal: false, vertical: true)
  }

  var bottomAction: some View {
    Button { send(store.mode == .code ? .findTapped : .joinTapped) } label: {
      Text(store.primaryButtonTitle)
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(store.mode == .code ? !store.canFindClass : !store.canJoin)
  }
}
