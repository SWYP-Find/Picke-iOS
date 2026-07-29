//
//  RecapPhilosopherCard.swift
//  Profile
//

import SwiftUI

import Entity
import Kingfisher
import PickeDesignKit

public struct RecapPhilosopherCard: View {
  private let card: RecapCard
  /// 공유 스냅샷용 — ImageRenderer 는 동기 렌더라 KFImage(비동기) 가 빈 채로 캡처된다.
  /// 미리 로드한 아바타 이미지를 주입하면 동기 렌더되어 스토리/게시물 공유에 이미지가 포함된다.
  private let avatarOverride: UIImage?

  public init(card: RecapCard, avatarOverride: UIImage? = nil) {
    self.card = card
    self.avatarOverride = avatarOverride
  }

  public var body: some View {
    VStack(spacing: 24) {
      VStack(spacing: 6) {
        Text("나의 철학자 유형")
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)

        Text(card.displayTypeName)
          .pretendardFont(.semiBold24)
          .foregroundStyle(.gray500)
      }

      avatar

      VStack(spacing: 32) {
        Text(card.description)
          .pretendardFont(.bodyMedium)
          .foregroundStyle(.gray400)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)

        if !card.keywordTags.isEmpty {
          HStack(spacing: 8) {
            ForEach(card.keywordTags, id: \.self) { tag in
              Text(tag)
                .pretendardFont(.semiBold12)
                .foregroundStyle(.primary500)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .roundedBackground(.beige50)
                .overlay(
                  RoundedRectangle(cornerRadius: .radiusDefault)
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
    .roundedBackground(.beige50)
    .overlay(
      RoundedRectangle(cornerRadius: .radiusDefault)
        .stroke(.beige600, lineWidth: 1)
    )
    .overlay(alignment: .top) {
      Rectangle()
        .fill(.primary500)
        .frame(height: 3)
    }
    .clipShape(RoundedRectangle(cornerRadius: .radiusDefault))
  }

  @ViewBuilder
  private var avatar: some View {
    ZStack {
      Circle().fill(.beige600)
      if let avatarOverride {
        // 공유 스냅샷: 사전 로드된 이미지를 동기 렌더.
        Image(uiImage: avatarOverride)
          .resizable()
          .scaledToFit()
          .padding(6)
      } else if !card.imageURL.isEmpty, let url = URL(string: card.imageURL) {
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
