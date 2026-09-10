//
//  TokenDTO.swift
//  AuthDomain
//
//  Created by Wonji Suh on 5/14/26.
//

import PickeNetworkInterface
import Foundation

public struct TokenDTO: Decodable {
  public let accessToken: String
  public let refreshToken: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
  }
}

/// `/api/v1/auth/refresh` 응답 타입 별칭
