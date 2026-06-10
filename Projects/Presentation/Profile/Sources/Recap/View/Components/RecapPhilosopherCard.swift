//
//  RecapPhilosopherCard.swift
//  Profile
//
//  내 철학자 유형 카드 — 상단 액센트 라인 + 유형명 + 아바타 + 설명 + 키워드 뱃지.
//  (잠금 화면에서도 재사용)
//

import SwiftUI

import DesignSystem
import Entity
import Kingfisher

public struct RecapPhilosopherCard: View {
  private let card: RecapCard

  public init(card: RecapCard) {
    self.card = card
  }

  public var body: some View {
    VStack(spacing: 24) {
      VStack(spacing: 6) {
        Text("나의 철학자 유형")
          .pretendardFont(family: .SemiBold, size: 13)
          .foregroundStyle(.primary500)

        Text(card.typeName)
          .pretendardFont(family: .SemiBold, size: 24)
          .foregroundStyle(.gray500)
      }

      avatar

      VStack(spacing: 32) {
        Text(card.description)
          .pretendardFont(family: .Regular, size: 14)
          .foregroundStyle(.gray400)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)

        if !card.keywordTags.isEmpty {
          HStack(spacing: 8) {
            ForEach(card.keywordTags, id: \.self) { tag in
              Text(tag)
                .pretendardFont(family: .SemiBold, size: 12)
                .foregroundStyle(.primary500)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
                .overlay(
                  RoundedRectangle(cornerRadius: 2)
                    .stroke(.primary100, lineWidth: 1)
                )
            }
          }
        }
      }
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 20)
    .frame(maxWidth: .infinity)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(
      RoundedRectangle(cornerRadius: 2)
        .stroke(.beige600, lineWidth: 1)
    )
    .overlay(alignment: .top) {
      Rectangle()
        .fill(.primary500)
        .frame(height: 3)
    }
    .clipShape(RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  private var avatar: some View {
    ZStack {
      Circle().fill(.beige600)
      if !card.imageURL.isEmpty, let url = URL(string: card.imageURL) {
        KFImage(url)
          .resizable()
          .scaledToFit()
          .padding(6)
      } else {
        Image(systemName: "brain.head.profile")
          .font(.system(size: 30))
          .foregroundStyle(.gray300)
      }
    }
    .frame(width: 68, height: 68)
    .clipShape(Circle())
  }
}
