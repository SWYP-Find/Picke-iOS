//
//  BattlePerspectiveDataDTO.swift
//  BattleDomain
//

import Foundation

public struct BattlePerspectivePageDataDTO: Decodable {
  public let items: [BattlePerspectiveDTO]
  public let nextCursor: String?
  public let hasNext: Bool
}

public struct BattlePerspectiveDTO: Decodable {
  public let perspectiveId: Int
  public let user: BattlePerspectiveUserDTO
  public let option: BattlePerspectiveOptionDTO
  public let content: String
  public let likeCount: Int
  public let commentCount: Int
  public let isLiked: Bool?
  public let isMyPerspective: Bool?
  public let createdAt: String?
}

public struct BattlePerspectiveUserDTO: Decodable {
  public let userTag: String?
  public let nickname: String?
  public let characterType: String?
  public let characterImageUrl: String?
}

public struct BattlePerspectiveOptionDTO: Decodable {
  public let optionId: Int
  public let label: String?
  public let title: String?
  public let stance: String?
}

public struct CreatePerspectiveDataDTO: Decodable {
  public let perspectiveId: Int
  public let status: String?
  public let createdAt: String?
}

public typealias BattlePerspectivePageResponseDTO = BaseResponseDTO<BattlePerspectivePageDataDTO>
public typealias CreatePerspectiveResponseDTO = BaseResponseDTO<CreatePerspectiveDataDTO>
