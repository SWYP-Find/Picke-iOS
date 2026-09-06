//
//  LoginDataDTO.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation
import Model

public struct LoginDataDTO: Decodable {
  public let accessToken: String
  public let refreshToken: String
  public let userTag: String
  public let status: String
  public let newUser: Bool

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case userTag = "user_tag"
    case status
    case newUser = "new_user"
  }
}

/// `/api/v1/auth/login/{provider}` 응답 타입 별칭
public typealias LoginResponseDTO = BaseResponseDTO<LoginDataDTO>
