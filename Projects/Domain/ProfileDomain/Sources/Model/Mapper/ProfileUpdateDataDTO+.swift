//
//  ProfileUpdateDataDTO+.swift
//  ProfileDomain
//

import Foundation
import ProfileDomainInterface

public extension ProfileUpdateDataDTO {
  func toDomain() -> UpdatedProfile {
    UpdatedProfile(
      userTag: userTag ?? "",
      nickname: nickname ?? "",
      characterType: characterType ?? "",
      updatedAt: updatedAt ?? ""
    )
  }
}
