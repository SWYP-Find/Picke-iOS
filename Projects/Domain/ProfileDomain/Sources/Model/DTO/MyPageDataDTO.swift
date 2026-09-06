//
//  MyPageDataDTO.swift
//  ProfileDomain
//

import PickeNetworkInterface
import Foundation

public struct MyPageDataDTO: Decodable {
  // philosopher 는 미확정(배틀 5개 미만) 시 null 로 내려와 옵셔널로 둔다.
  public let profile: MyProfileDTO?
  public let philosopher: MyPhilosopherDTO?
  public let tier: MyTierDTO?
}

public struct MyProfileDTO: Decodable {
  public let userTag: String?
  public let nickname: String?
  public let characterType: String?
  public let characterLabel: String?
  public let characterImageUrl: String?
  public let mannerTemperature: Double?
}

public struct MyPhilosopherDTO: Decodable {
  public let philosopherType: String?
  public let philosopherLabel: String?
  public let typeName: String?
  public let description: String?
  public let imageUrl: String?
}

public struct MyTierDTO: Decodable {
  public let tierCode: String?
  public let tierLabel: String?
  public let currentPoint: Int?
}

public typealias MyPageResponseDTO = BaseResponseDTO<MyPageDataDTO>
