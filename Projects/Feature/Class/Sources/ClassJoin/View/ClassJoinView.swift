//
//  ClassJoinView.swift
//  Class
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
    ZStack(alignment: .bottom) {
      Color.clear
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { send(.backTapped) }
      switch store.mode {
      case .code:
        codeSheet()
      case .nickname:
        nicknameSheet()
      }
    }
  }
}

private extension ClassJoinView {
  @ViewBuilder
  func codeSheet() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      sheetHandle
      contentSection()
      primaryButton
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
    .padding(.bottom, 32)
    .frame(maxWidth: .infinity)
    .background(
      UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
        .fill(.beige50)
        .ignoresSafeArea(edges: .bottom)
    )
  }

  @ViewBuilder
  func contentSection() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      titleSection()

      codeSection()

      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .pretendardFont(.bodySmall)
          .foregroundStyle(.errorDefault)
      }
    }
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("공유받은 코드로\n클래스에 참여하세요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      Text("전달받은 6자리 코드를 입력해 주세요.")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func codeSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("참여 코드")
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray800)

      ZStack {
        HStack(spacing: 8) {
          ForEach(0 ..< 6, id: \.self) { index in
            Text(index < store.joinCode.count ? String(Array(store.joinCode)[index]) : "")
              .pretendardFont(.semiBold24)
              .foregroundStyle(.gray800)
              .frame(maxWidth: .infinity)
              .frame(height: 54)
              .background(.beige50)
              .overlay {
                Rectangle()
                  .strokeBorder(.beige600, lineWidth: 1)
              }
          }
        }
        .accessibilityHidden(true)

        TextField("", text: $store.joinCode)
          .textInputAutocapitalization(.characters)
          .autocorrectionDisabled()
          .keyboardType(.asciiCapable)
          .textContentType(.oneTimeCode)
          .focused($isCodeFocused)
          .accessibilityLabel("참여 코드, 6자리")
          .foregroundStyle(.clear)
          .tint(.clear)
      }
      .contentShape(Rectangle())
      .onTapGesture { isCodeFocused = true }

      helpCard
    }
  }

  var helpCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("코드를 찾을 수 없나요?")
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray800)

      Text("클래스를 만든 선생님이나 모임장에게\n참여 코드를 확인해 주세요.")
        .pretendardFont(.bodySmall)
        .foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(.beige100)
  }

  @ViewBuilder
  func nicknameSheet() -> some View {
    VStack(alignment: .leading, spacing: 20) {
      sheetHandle

      VStack(alignment: .leading, spacing: 6) {
        Text("이름을 입력해주세요")
          .pretendardFont(.semiBold24)
          .foregroundStyle(.gray800)
        Text("이 클래스에서만 보이는 이름이에요.\n입장 후에도 수정할 수 있어요.")
          .pretendardFont(family: .Regular, size: 14)
          .foregroundStyle(.gray300)
      }

      nicknameInput
      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .pretendardFont(.bodySmall)
          .foregroundStyle(.errorDefault)
      }
      joinButton
    }
    .padding(.top, 12)
    .padding(.horizontal, 16)
    .padding(.bottom, 32)
    .frame(maxWidth: .infinity)
    .background(
      UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
        .fill(.beige50)
        .ignoresSafeArea(edges: .bottom)
    )
  }

  var sheetHandle: some View {
    Capsule()
      .fill(.gray50)
      .frame(width: 40, height: 4)
      .frame(maxWidth: .infinity)
      .padding(.bottom, 10)
  }

  var nicknameInput: some View {
    TextField("이름을 입력해주세요", text: $store.nickname)
      .textInputAutocapitalization(.never)
      .pickeTextField(height: 52)
  }

  var joinButton: some View {
    Button { send(.joinTapped) } label: {
      Text("입장하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canJoin)
  }

  var primaryButton: some View {
    Button { send(.findTapped) } label: {
      Text("클래스 참여하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canFindClass)
  }
}
