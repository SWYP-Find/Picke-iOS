//
//  PerspectiveLikeDataDTO.swift
//  PerspectiveDomain
//

import Foundation

import PickeNetworkInterface

/// 관점 좋아요/취소/조회 응답 페이로드.
public struct PerspectiveLikeDataDTO: Decodable {
  public let perspectiveId: Int
  public let likeCount: Int
  /// perspective 좋아요 응답에는 isLiked 가 없어 옵셔널.
  public let isLiked: Bool?
}
