//
//  BattleDetailDataDTO.swift
//  BattleDomain
//

import Foundation

import PickeNetworkInterface

public struct BattleDetailDataDTO: Decodable {
  public let battleInfo: BattleInfoDTO
  public let description: String
  public let shareUrl: String
  public let userVoteStatus: String?
  public let currentStep: String?
  public let categoryTags: [BattleTagDTO]
  public let philosopherTags: [BattleTagDTO]
  public let valueTags: [BattleTagDTO]

  enum CodingKeys: String, CodingKey {
    case battleInfo, description, shareUrl, userVoteStatus, currentStep
    case categoryTags, philosopherTags, valueTags
  }

  // 일부 필드가 누락/null 이어도 배틀 상세(→사전투표) 전체 디코딩이 실패하지 않도록 방어.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    battleInfo = try container.decode(BattleInfoDTO.self, forKey: .battleInfo)
    description = (try? container.decodeIfPresent(String.self, forKey: .description)) ?? ""
    shareUrl = (try? container.decodeIfPresent(String.self, forKey: .shareUrl)) ?? ""
    userVoteStatus = try? container.decodeIfPresent(String.self, forKey: .userVoteStatus)
    currentStep = try? container.decodeIfPresent(String.self, forKey: .currentStep)
    categoryTags = (try? container.decodeIfPresent([BattleTagDTO].self, forKey: .categoryTags)) ?? []
    philosopherTags = (try? container.decodeIfPresent([BattleTagDTO].self, forKey: .philosopherTags)) ?? []
    valueTags = (try? container.decodeIfPresent([BattleTagDTO].self, forKey: .valueTags)) ?? []
  }
}

public struct BattleInfoDTO: Decodable {
  public let battleId: Int
  public let title: String
  public let summary: String
  public let thumbnailUrl: String
  public let viewCount: Int
  public let participantsCount: Int
  public let audioDuration: Int
  public let tags: [BattleTagDTO]
  public let options: [BattleOptionDTO]

  enum CodingKeys: String, CodingKey {
    case battleId, title, summary, thumbnailUrl, viewCount, participantsCount, audioDuration, tags, options
  }

  // battleId 외 필드가 누락/null 이어도 디코딩이 실패하지 않도록 방어.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    battleId = try container.decode(Int.self, forKey: .battleId)
    title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
    summary = (try? container.decodeIfPresent(String.self, forKey: .summary)) ?? ""
    thumbnailUrl = (try? container.decodeIfPresent(String.self, forKey: .thumbnailUrl)) ?? ""
    viewCount = (try? container.decodeIfPresent(Int.self, forKey: .viewCount)) ?? 0
    participantsCount = (try? container.decodeIfPresent(Int.self, forKey: .participantsCount)) ?? 0
    audioDuration = (try? container.decodeIfPresent(Int.self, forKey: .audioDuration)) ?? 0
    tags = (try? container.decodeIfPresent([BattleTagDTO].self, forKey: .tags)) ?? []
    options = (try? container.decodeIfPresent([BattleOptionDTO].self, forKey: .options)) ?? []
  }
}

public struct BattleOptionDTO: Decodable {
  public let optionId: Int
  public let label: String?
  public let title: String
  public let stance: String
  public let representative: String
  public let imageUrl: String
  // today 배틀 옵션 응답엔 tags 가 없으므로 옵셔널.
  public let tags: [BattleTagDTO]?

  enum CodingKeys: String, CodingKey {
    case optionId, label, title, stance, representative, imageUrl, tags
  }

  // optionId 외 필드가 누락/null 이어도 디코딩이 실패하지 않도록 방어.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    optionId = try container.decode(Int.self, forKey: .optionId)
    label = try? container.decodeIfPresent(String.self, forKey: .label)
    title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
    stance = (try? container.decodeIfPresent(String.self, forKey: .stance)) ?? ""
    representative = (try? container.decodeIfPresent(String.self, forKey: .representative)) ?? ""
    imageUrl = (try? container.decodeIfPresent(String.self, forKey: .imageUrl)) ?? ""
    tags = try? container.decodeIfPresent([BattleTagDTO].self, forKey: .tags)
  }
}

public struct BattleTagDTO: Decodable {
  public let tagId: Int
  public let name: String
  public let type: String
}
