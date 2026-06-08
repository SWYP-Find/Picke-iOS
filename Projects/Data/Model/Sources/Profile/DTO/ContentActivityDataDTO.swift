//
//  ContentActivityDataDTO.swift
//  Model
//
//  `GET /api/v1/me/content-activities` 응답 DTO.
//

import Foundation

public struct ContentActivityDataDTO: Decodable {
  public let items: [ContentActivityItemDTO]?
  public let nextOffset: Int?
  public let hasNext: Bool?
}

public struct ContentActivityItemDTO: Decodable {
  public let activityId: String?
  public let activityType: String?
  public let perspectiveId: String?
  public let battleId: String?
  public let battleTitle: String?
  public let author: ContentActivityAuthorDTO?
  public let voteSide: String?
  public let content: String?
  public let likeCount: Int?
  public let createdAt: String?
}

public struct ContentActivityAuthorDTO: Decodable {
  public let userTag: String?
  public let nickname: String?
  public let characterType: String?
  public let characterImageUrl: String?
}

public typealias ContentActivityResponseDTO = BaseResponseDTO<ContentActivityDataDTO>
