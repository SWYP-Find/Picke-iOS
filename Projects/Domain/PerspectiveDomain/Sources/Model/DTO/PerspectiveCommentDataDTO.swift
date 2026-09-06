//
//  PerspectiveCommentDataDTO.swift
//  PerspectiveDomain
//

import Foundation

public struct PerspectiveCommentPageDataDTO: Decodable {
  public let items: [PerspectiveCommentDTO]
  public let nextCursor: String?
  public let hasNext: Bool
}

public struct PerspectiveCommentDTO: Decodable {
  public let commentId: Int
  public let user: PerspectiveCommentUserDTO
  public let stance: String?
  public let content: String
  public let likeCount: Int
  public let isLiked: Bool?
  public let isMine: Bool?
  public let createdAt: String?
}

public struct PerspectiveCommentUserDTO: Decodable {
  public let userTag: String?
  public let nickname: String?
  public let characterType: String?
  public let characterImageUrl: String?
}

/// POST/PUT /api/v1/perspectives/{pid}/comments[/{cid}] 응답.
public struct PerspectiveCommentMutationDataDTO: Decodable {
  public let commentId: Int
  public let content: String
  public let updatedAt: String?
}

public typealias PerspectiveCommentPageResponseDTO = BaseResponseDTO<PerspectiveCommentPageDataDTO>
public typealias PerspectiveCommentMutationResponseDTO = BaseResponseDTO<PerspectiveCommentMutationDataDTO>
public typealias PerspectiveDetailResponseDTO = BaseResponseDTO<BattlePerspectiveDTO>
