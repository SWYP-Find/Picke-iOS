//
//  ProfileUpdateDataDTO.swift
//  ProfileDomain
//
//  Created by Picke on 10/11/26.
//

import PickeNetworkInterface
import Foundation

public struct ProfileUpdateDataDTO: Decodable {
  public let userTag: String?
  public let nickname: String?
  public let characterType: String?
  public let updatedAt: String?
}
