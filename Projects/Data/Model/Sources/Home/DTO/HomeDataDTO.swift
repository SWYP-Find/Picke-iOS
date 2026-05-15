//
//  HomeDataDTO.swift
//  Model
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

/// `GET /api/v1/home` 의 `data` 필드 페이로드.
public struct HomeDataDTO: Decodable {
  public let newNotice: Bool
  public let editorPicks: [EditorPickDTO]
  public let trendingBattles: [TrendingBattleDTO]
  public let bestBattles: [BestBattleDTO]
  public let todayQuizzes: [TodayQuizDTO]
  public let todayVotes: [TodayVoteDTO]
  public let newBattles: [NewBattleDTO]
}

public struct TagDTO: Decodable, Equatable {
  public let tagId: Int
  public let name: String
  public let type: String
}

public struct EditorPickDTO: Decodable, Identifiable {
  public let battleId: Int
  public let thumbnailUrl: String?
  public let optionATitle: String
  public let optionBTitle: String
  public let title: String
  public let summary: String
  public let tags: [TagDTO]
  public let viewCount: Int

  public var id: Int { battleId }
}

public struct TrendingBattleDTO: Decodable, Identifiable {
  public let battleId: Int
  public let thumbnailUrl: String?
  public let title: String
  public let tags: [TagDTO]
  public let audioDuration: Int
  public let viewCount: Int

  public var id: Int { battleId }
}

public struct BestBattleDTO: Decodable, Identifiable {
  public let battleId: Int
  public let philosopherA: String
  public let philosopherB: String
  public let title: String
  public let tags: [TagDTO]
  public let audioDuration: Int
  public let viewCount: Int

  public var id: Int { battleId }
}

public struct TodayQuizDTO: Decodable, Identifiable {
  public let battleId: Int
  public let title: String
  public let summary: String
  public let participantsCount: Int
  public let itemA: String
  public let itemADesc: String
  public let isCorrectA: Bool
  public let itemB: String
  public let itemBDesc: String
  public let isCorrectB: Bool

  public var id: Int { battleId }
}

public struct TodayVoteDTO: Decodable, Identifiable {
  public let battleId: Int
  public let titlePrefix: String
  public let titleSuffix: String
  public let summary: String
  public let participantsCount: Int
  public let options: [VoteOptionDTO]

  public var id: Int { battleId }
}

public struct VoteOptionDTO: Decodable, Equatable {
  public let label: String
  public let title: String
}

public struct NewBattleDTO: Decodable, Identifiable {
  public let battleId: Int
  public let thumbnailUrl: String?
  public let title: String
  public let summary: String
  public let philosopherA: String
  public let optionATitle: String
  public let philosopherAImageUrl: String?
  public let philosopherB: String
  public let optionBTitle: String
  public let philosopherBImageUrl: String?
  public let tags: [TagDTO]
  public let audioDuration: Int
  public let viewCount: Int

  public var id: Int { battleId }
}

/// `GET /api/v1/home` 응답 타입 별칭.
public typealias HomeResponseDTO = BaseResponseDTO<HomeDataDTO>
