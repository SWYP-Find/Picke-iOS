//
//  MyPageDataDTO.swift
//  Model
//
//  `GET /api/v1/me/mypage` 응답 DTO.
//

import Foundation

public struct MyPageDataDTO: Decodable {
  public let profile: MyProfileDTO
  public let philosopher: MyPhilosopherDTO
  public let tier: MyTierDTO
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
