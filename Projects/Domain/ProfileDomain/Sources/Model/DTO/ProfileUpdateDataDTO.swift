//
//  ProfileUpdateDataDTO.swift
//  ProfileDomain
//

import PickeNetworkInterface
import Foundation

public struct ProfileUpdateDataDTO: Decodable {
  public let userTag: String?
  public let nickname: String?
  public let characterType: String?
  public let updatedAt: String?
}

public typealias ProfileUpdateResponseDTO = BaseResponseDTO<ProfileUpdateDataDTO>
