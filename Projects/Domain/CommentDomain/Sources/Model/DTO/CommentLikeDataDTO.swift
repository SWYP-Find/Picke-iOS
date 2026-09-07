//
//  CommentLikeDataDTO.swift
//  CommentDomain
//

import PickeNetworkInterface
import Foundation


public struct CommentLikeDataDTO: Decodable {
  public let perspectiveId: Int
  public let likeCount: Int
  /// perspective 좋아요 응답에는 isLiked 가 없어 옵셔널.
  public let isLiked: Bool?
}
