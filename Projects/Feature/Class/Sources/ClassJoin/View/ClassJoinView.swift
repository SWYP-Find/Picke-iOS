//
//  ClassJoinView.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassJoinFeature.self)
public struct ClassJoinView: View {
  @Bindable public var store: StoreOf<ClassJoinFeature>

  public init(store: StoreOf<ClassJoinFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.backTapped) },
        centerTitle: "클래스 참여하기"
      )
      .foregroundStyle(.gray500)

      ScrollView {
        contentSection()
          .padding(16)
      }
      .scrollIndicators(.hidden)

      primaryButton
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    .screenBackground()
    .hidesSystemBars()
  }
}

private extension ClassJoinView {
  @ViewBuilder
  func contentSection() -> some View {
    VStack(alignment: .leading, spacing: 28) {
      titleSection()

      if store.preview == nil {
        codeSection()
      } else {
        previewSection()
        nicknameSection()
      }

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
      Text(store.preview == nil ? "참여 코드를 입력해주세요" : "이름을 입력해주세요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)

      Text(
        store.preview == nil
          ? "선생님에게 받은 코드를 입력하면 클래스에 참여할 수 있어요."
          : "이 클래스에서만 보이는 이름이에요."
      )
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
  func previewSection() -> some View {
    if let preview = store.preview {
      VStack(alignment: .leading, spacing: 12) {
        Text("참여할 클래스")
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)

        VStack(alignment: .leading, spacing: 8) {
          Text(preview.name)
            .pretendardFont(family: .SemiBold, size: 18)
            .foregroundStyle(.gray800)

          Text(preview.battle.title)
            .pretendardFont(.medium15)
            .foregroundStyle(.gray500)

          Text("현재 (preview.memberCount)명이 참여 중")
            .pretendardFont(.medium13)
            .foregroundStyle(.gray300)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .pickeCard(.beige50, border: .beige600)
      }
    }
  }

  @ViewBuilder
  func nicknameSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("이름")
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray800)

      TextField(
        "입력해주세요",
        text: $store.nickname
      )
      .textInputAutocapitalization(.never)
      .pickeTextField()
    }
  }

  var primaryButton: some View {
    Button {
      send(store.preview == nil ? .findTapped : .joinTapped)
    } label: {
      Text(store.preview == nil ? "클래스 찾기" : "참여하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
    .disabled(store.preview == nil ? !store.canFindClass : !store.canJoin)
  }
}
