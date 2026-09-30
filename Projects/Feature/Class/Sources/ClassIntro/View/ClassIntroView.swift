//
//  ClassIntroView.swift
//  Class
//

import SwiftUI

import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI

@ViewAction(for: ClassIntroFeature.self)
public struct ClassIntroView: View {
  @Bindable public var store: StoreOf<ClassIntroFeature>

  public init(store: StoreOf<ClassIntroFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(centerTitle: "클래스")
        .foregroundStyle(.white)

      VStack(alignment: .leading, spacing: 0) {
        titleSection()
        Spacer(minLength: 24)
        menuCards()
          .padding(.bottom, 16)
        createButton()
        ticketButton()
      }
      .padding(.top, 24)
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
    }
    .background(backgroundImage())
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassIntroView {
  @ViewBuilder
  func backgroundImage() -> some View {
    ZStack {
      Color.beige200
      Image(asset: .classIntroBackground)
        .resizable()
        .scaledToFill()
    }
    .ignoresSafeArea()
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("함께 생각하는\n수업을 시작해 보세요")
        .pretendardFont(family: .SemiBold, size: 24)
        .lineSpacing(7)
        .foregroundStyle(.white)

      Text("콘텐츠를 고르고, 클래스로 함께 나눠요.")
        .pretendardFont(family: .SemiBold, size: 16)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func menuCards() -> some View {
    HStack(spacing: 6) {
      ClassMenuCard(
        title: "클래스 참여하기",
        description: "참여 코드 입력",
        image: .classJoin,
        action: { send(.joinTapped) }
      )

      ClassMenuCard(
        title: "내 클래스",
        description: "참여중인 클래스",
        image: .classMine,
        action: { send(.myClassesTapped) }
      )
    }
  }

  @ViewBuilder
  func createButton() -> some View {
    Button {
      send(.createTapped)
    } label: {
      Text("새 클래스 만들기")
    }
    .ctaButtonStyle(.primary, size: .large, height: 52)
  }

  @ViewBuilder
  func ticketButton() -> some View {
    Button {
      send(.ticketTapped)
    } label: {
      Text("이용권 등록하기")
        .pretendardFont(family: .Medium, size: 14)
        .foregroundStyle(.gray300)
        .underline()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    .buttonStyle(.plain)
  }
}
