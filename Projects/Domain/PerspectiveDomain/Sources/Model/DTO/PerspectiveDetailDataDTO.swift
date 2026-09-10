//
//  PerspectiveDetailDataDTO.swift
//  PerspectiveDomain
//

import Foundation

import PickeNetworkInterface

/// 관점 상세 응답 페이로드.
///
/// 배틀 목록의 관점(`BattlePerspectiveDTO`) 과 와이어 포맷은 같지만,
/// 이 엔드포인트는 PerspectiveDomain 소유이므로 DTO 도 여기서 따로 갖는다.
/// (도메인끼리 서로의 구현 모듈을 참조하지 않기 위함 — 계약은 Interface 의 `BattlePerspective` 로만 오간다.)
public struct PerspectiveDetailDataDTO: Decodable {
  public let perspectiveId: Int
  public let user: PerspectiveDetailUserDTO
  public let option: PerspectiveDetailOptionDTO
  public let content: String
  public let likeCount: Int
  public let commentCount: Int
  public let isLiked: Bool?
  public let isMyPerspective: Bool?
  public let createdAt: String?
}

public struct PerspectiveDetailUserDTO: Decodable {
  public let userTag: String?
  public let nickname: String?
  public let characterType: String?
  public let characterImageUrl: String?
}

public struct PerspectiveDetailOptionDTO: Decodable {
  public let optionId: Int
  public let label: String?
  public let title: String?
  public let stance: String?
}
