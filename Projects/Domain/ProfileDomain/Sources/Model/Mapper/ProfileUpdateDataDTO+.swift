//
//  ProfileUpdateDataDTO+.swift
//  ProfileDomain
//
//  Created by Picke on 10/11/26.
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
