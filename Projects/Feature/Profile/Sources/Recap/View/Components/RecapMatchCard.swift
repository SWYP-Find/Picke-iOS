//
//  RecapMatchCard.swift
//  Profile
//

import SwiftUI

import Kingfisher
import PickeDesignKit
import ProfileDomainInterface

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
        Text(card.displayTypeName)
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
    .pickeCard(.beige50, border: .beige600)
  }

  @ViewBuilder
  private var avatar: some View {
    ZStack {
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
    .pickeAvatar(size: 40)
  }
}
