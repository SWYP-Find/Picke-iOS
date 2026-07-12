//
//  RecapMatchCard.swift
//  Profile
//
//  궁합 유형 카드 (BEST / WORST) — 아바타 + 유형명 + 설명.
//  (잠금 화면에서도 재사용)
//

import SwiftUI

import PickeDesignKit
import Entity
import Kingfisher

public struct RecapMatchCard: View {
  private let card: RecapCard
  private let isBest: Bool

  public init(card: RecapCard, isBest: Bool) {
    self.card = card
    self.isBest = isBest
  }

  public var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 4) {
        Image(systemName: isBest ? "hand.thumbsup" : "hand.thumbsdown")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(isBest ? .secondary500 : .gray400)
        Text(isBest ? "BEST" : "WORST")
          .pretendardFont(.bold10)
          .foregroundStyle(isBest ? .secondary500 : .gray400)
      }

      avatar

      VStack(spacing: 6) {
        Text(card.typeName)
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray500)

        Text(card.description)
          .pretendardFont(.regular11)
          .foregroundStyle(.gray300)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .roundedBackground(.beige50)
    .overlay(
      RoundedRectangle(cornerRadius: .radiusDefault)
        .stroke(.beige600, lineWidth: 1)
    )
  }

  @ViewBuilder
  private var avatar: some View {
    ZStack {
      Circle().fill(.beige600)
      if !card.imageURL.isEmpty, let url = URL(string: card.imageURL) {
        KFImage(url)
          .resizable()
          .scaledToFit()
          .padding(4)
      } else {
        Image(systemName: "brain.head.profile")
          .font(.system(size: 18))
          .foregroundStyle(.gray300)
      }
    }
    .frame(width: 40, height: 40)
    .clipShape(Circle())
  }
}
