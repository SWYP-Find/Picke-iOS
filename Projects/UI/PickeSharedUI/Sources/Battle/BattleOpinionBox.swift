//
//  BattleOpinionBox.swift
//  PickeSharedUI
//
//  Created by Picke on 11/10/26.
//

import PickeDesignKit
import SwiftUI

/// Android `BattleOpinionBox` — 프로필 40 + 입장(12 Medium)·대표(10 SemiBold) 한 줄씩.
/// 홈 "새로운 배틀" 카드와 추천 카드가 함께 쓴다.
public struct BattleOpinionBox: View {
  let opinion: String
  let name: String
  let imageURL: URL?

  public init(
    opinion: String,
    name: String,
    imageURL: URL?
  ) {
    self.opinion = opinion
    self.name = name
    self.imageURL = imageURL
  }

  public var body: some View {
    HStack(spacing: 4) {
      profileImage
      VStack(alignment: .leading, spacing: 2) {
        Text(opinion)
          .pretendardFont(.labelSmall)
          .foregroundStyle(.textSubtle)
          .lineLimit(1)
          .truncationMode(.tail)
        Text(name)
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.textMuted)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .pickeCard(
      .surfaceBeigeSubtle,
      border: .borderBeigeDisabled,
      insideBorder: true
    )
  }

  /// Android `ProfileImage`(CHARACTER) — 40 원 배경 + 가운데 2/3 크기 이미지(fit).
  private var profileImage: some View {
    Circle()
      .fill(.borderBeigeDefault)
      .overlay {
        if let imageURL {
          PickeRemoteImage(url: imageURL) {
            Color.clear
          }
          .content(.fit)
          .frame(width: 40 * 2 / 3, height: 40 * 2 / 3)
        }
      }
      .frame(width: 40, height: 40)
  }
}
