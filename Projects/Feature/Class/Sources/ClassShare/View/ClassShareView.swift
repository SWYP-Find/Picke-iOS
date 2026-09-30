//
//  ClassShareView.swift
//  Class
//

import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassShareFeature.self)
public struct ClassShareView: View {
  @Bindable public var store: StoreOf<ClassShareFeature>

  public init(store: StoreOf<ClassShareFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(
        onBack: { send(.closeTapped) },
        centerTitle: "클래스 공유하기"
      )
      .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          intro()
          codeCard()
          battleSection()
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize)

      enterButton
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    .screenBackground()
    .hidesSystemBars()
  }
}

private extension ClassShareView {
  @ViewBuilder
  func intro() -> some View {
    VStack(spacing: 12) {
      Text("클래스가 준비됐어요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray500)

      Text("참여 코드를 학생들에게 공유해주세요")
        .pretendardFont(.headingMedium)
        .foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func codeCard() -> some View {
    VStack(spacing: 12) {
      VStack(spacing: 4) {
        Text(store.room.name)
          .pretendardFont(.bold18)
          .foregroundStyle(.gray800)

        if let deadlineText = store.deadlineText {
          Text(deadlineText)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.gray300)
        }
      }

      VStack(spacing: 12) {
        Text("참여 코드")
          .pretendardFont(.labelMedium)
          .foregroundStyle(.gray300)

        Text(store.room.joinCode)
          .pretendardFont(.headingXXLarge)
          .foregroundStyle(.primary500)
          .textSelection(.enabled)
      }

      shareButton
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .pickeCard(.beige50, border: .beige600)
  }

  var shareButton: some View {
    ShareLink(item: store.shareMessage) {
      Text("코드 공유하기")
        .pretendardFont(.labelLarge)
        .foregroundStyle(.primary500)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(.primary50, in: RoundedRectangle(cornerRadius: .radiusDefault))
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func battleSection() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("선택한 배틀")
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray800)

      ClassSelectedBattleCard(battle: store.room.battle)
    }
  }

  var enterButton: some View {
    Button {
      send(.enterClassTapped)
    } label: {
      Text("클래스로 이동하기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
  }
}
