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
      Text("참여 코드를 입력해주세요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      Text("선생님에게 받은 코드를 입력하면 클래스에 참여할 수 있어요.")
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

      TextField(
        "예) PK9T3S",
        text: $store.joinCode
      )
      .textInputAutocapitalization(.characters)
      .autocorrectionDisabled()
      .pickeTextField()
    }
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
      Text("클래스 찾기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(!store.canFindClass)
  }
}
