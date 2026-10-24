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
        centerTitle: store.mode == .code ? nil : (store.mode == .ownerName ? "이름 입력" : "클래스 참여"),
        leadingTitle: store.mode == .code ? "클래스 참여" : nil,
        leadingSpacing: 12
      )
      .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: store.mode == .code ? 26 : 24) {
          titleSection()
          switch store.mode {
          case .code:
            codeSection()
          case .nickname, .ownerName:
            nicknameSection()
          }
        }
        .padding(16)
        .padding(.top, store.mode == .code ? 6 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)

      bottomActions()
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
    VStack(alignment: .leading, spacing: store.mode == .code ? 14 : 8) {
      Text(store.mode == .code ? "공유받은 코드로\n클래스에 참여하세요" : "이름을 입력해주세요")
        .pretendardFont(.semiBold24)
        .lineSpacing(store.mode == .code ? 7 : 2.4)
        .foregroundStyle(.gray800)

      Text(store.mode == .code
        ? "선생님이나 모임장이 전달한\n6자리 코드를 입력해 주세요."
        : "이 클래스에서만 보이는 이름이에요.\n입장 후에도 수정할 수 있어요.")
        .pretendardFont(.bodyMedium)
        .lineSpacing(4)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func codeSection() -> some View {
    VStack(alignment: .leading, spacing: 29) {
      VStack(alignment: .leading, spacing: 12) {
        Text("참여 코드")
          .pretendardFont(.headingMedium)
          .foregroundStyle(.gray800)

        TextField(
          "",
          text: $store.joinCode,
          prompt: Text("6자리 코드를 입력해 주세요")
            .font(.pretendardFontFamily(family: .Regular, size: 14))
            .tracking(0)
            .foregroundStyle(.gray300)
        )
          .textInputAutocapitalization(.characters)
          .autocorrectionDisabled()
          .keyboardType(.asciiCapable)
          .textContentType(.oneTimeCode)
          .focused($isCodeFocused)
          .accessibilityLabel("참여 코드, 6자리")
          .tracking(4)
          .pickeTextField(
            height: 52,
            font: .headingLarge
          )
          .overlay {
            if store.errorMessage != nil {
              RoundedRectangle(cornerRadius: 2)
                .strokeBorder(.borderErrorDefault, lineWidth: 1)
            }
          }

        if let message = store.errorMessage {
          errorLabel(message)
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("코드를 찾을 수 없나요?")
          .pretendardFont(.headingSmall)
          .foregroundStyle(.gray800)

        Text("클래스를 만든 선생님이나 모임장에게\n참여 코드를 확인해 주세요.")
          .pretendardFont(.bodySmall)
          .foregroundStyle(.gray400)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(.beige200)
    }
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

  @ViewBuilder
  func bottomActions() -> some View {
    VStack(spacing: 8) {
      Button { send(store.mode == .code ? .findTapped : .joinTapped) } label: {
        Text(store.primaryButtonTitle)
      }
      .ctaButtonStyle(.primary, size: .large, height: 52)
      .disabled(store.mode == .code ? !store.canFindClass : !store.canJoin)

      if store.mode == .code {
        Button { send(.createClassTapped) } label: {
          Text("클래스 새로 만들기")
        }
        .ctaButtonStyle(.primary, size: .large, height: 52)
        .disabled(store.isLoading)
      }
    }
  }
}
