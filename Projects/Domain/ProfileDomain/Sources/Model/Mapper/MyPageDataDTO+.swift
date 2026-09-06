//
//  MyPageDataDTO+.swift
//  Model
//

import ProfileDomainInterface
import Foundation

public extension MyPageDataDTO {
  func toDomain() -> MyPage {
    MyPage(
      profile: profile?.toDomain() ?? .empty,
      philosopher: philosopher?.toDomain() ?? .empty,
      tier: tier?.toDomain() ?? .empty
    )
  }
}

public extension MyProfileDTO {
  func toDomain() -> MyProfile {
    MyProfile(
      userTag: userTag ?? "",
      nickname: nickname ?? "",
      characterType: characterType ?? "",
      characterLabel: characterLabel ?? "",
      characterImageURL: characterImageUrl ?? "",
      mannerTemperature: mannerTemperature ?? 0
    )
  }
}

public extension MyPhilosopherDTO {
  func toDomain() -> MyPhilosopher {
    MyPhilosopher(
      philosopherType: philosopherType ?? "",
      philosopherLabel: philosopherLabel ?? "",
      typeName: typeName ?? "",
      description: description ?? "",
      imageURL: imageUrl ?? ""
    )
  }
}

public extension MyTierDTO {
  func toDomain() -> MyTier {
    MyTier(
      tierCode: tierCode ?? "",
      tierLabel: tierLabel ?? "",
      currentPoint: currentPoint ?? 0
    )
  }
}
