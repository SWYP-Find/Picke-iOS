//
//  CommentLikeDataDTO.swift
//  Model
//

import Foundation

public struct CommentLikeDataDTO: Decodable {
  public let perspectiveId: Int
  public let likeCount: Int
  public let isLiked: Bool
}

public typealias CommentLikeResponseDTO = BaseResponseDTO<CommentLikeDataDTO>
