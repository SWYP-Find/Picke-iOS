//
//  ClassShareView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI
import UIKit

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
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassShareView {
  @ViewBuilder
  func intro() -> some View {
    VStack(spacing: 6) {
      Text("클래스가 준비됐어요")
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .frame(minHeight: 31)

      Text("참여 코드를 멤버들에게 공유해주세요")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 23)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func codeCard() -> some View {
    VStack(spacing: 16) {
      VStack(spacing: 4) {
        Text(store.room.name)
          .pretendardFont(.bold18)
          .foregroundStyle(.gray800)
          .frame(minHeight: 23)

        if let deadlineText = store.deadlineText {
          Text(deadlineText)
            .pretendardFont(.labelMedium)
            .foregroundStyle(.gray300)
            .frame(minHeight: 20)
        }
      }

      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
        .accessibilityHidden(true)

      VStack(spacing: 4) {
        Text("참여 코드")
          .pretendardFont(.labelMedium)
          .foregroundStyle(.gray300)
          .frame(minHeight: 20)

        Text(store.room.joinCode)
          .pretendardFont(.headingXXLarge)
          .tracking(-0.75)
          .foregroundStyle(.primary500)
          .frame(minHeight: 38)
          .textSelection(.enabled)
      }

      shareControls()
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .pickeCard(.beige50, border: .beige600)
  }

  @ViewBuilder
  func shareControls() -> some View {
    HStack(spacing: 8) {
      shareButton
      copyButton
    }
  }

  var copyButton: some View {
    Button {
      UIPasteboard.general.string = store.room.joinCode
      UIAccessibility.post(notification: .announcement, argument: "참여 코드를 복사했어요")
    } label: {
      Image(systemName: "square.on.square")
        .resizable()
        .scaledToFit()
        .frame(width: 18, height: 18)
        .foregroundStyle(.primary500)
        .frame(width: 52, height: 52)
        .background(.beige50, in: RoundedRectangle(cornerRadius: .radiusDefault))
        .overlay {
          RoundedRectangle(cornerRadius: .radiusDefault)
            .strokeBorder(.beige600, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("참여 코드 복사")
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
