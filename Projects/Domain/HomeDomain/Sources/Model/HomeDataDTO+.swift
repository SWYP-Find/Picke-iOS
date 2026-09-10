//
//  HomeDataDTO+.swift
//  HomeDomain
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation
import HomeDomainInterface

public extension TagDTO {
  func toDomain() -> BattleTag {
    BattleTag(tagId: tagId, name: name, type: TagType(rawValue: type))
  }
}

public extension EditorPickDTO {
  func toDomain(
    position: Int,
    total: Int
  ) -> HeroBattle {
    HeroBattle(
      battleId: battleId,
      badge: "EDITOR PICK",
      position: position,
      total: total,
      thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
      optionA: optionATitle,
      optionB: optionBTitle,
      title: title,
      summary: summary,
      tags: tags.map { $0.toDomain() },
      viewCount: viewCount
    )
  }
}

public extension TrendingBattleDTO {
  func toDomain() -> HotBattle {
    HotBattle(
      battleId: battleId,
      thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
      title: title,
      tags: tags.map { $0.toDomain() },
      audioDuration: audioDuration,
      viewCount: viewCount
    )
  }
}

public extension BestBattleDTO {
  func toDomain(rank: Int) -> BestBattle {
    BestBattle(
      battleId: battleId,
      rank: rank,
      philosopherA: philosopherA,
      philosopherB: philosopherB,
      title: title,
      tags: tags.map { $0.toDomain() },
      audioDuration: audioDuration,
      viewCount: viewCount
    )
  }
}

public extension TodayQuizDTO {
  func toDomain() -> QuizQuestion {
    QuizQuestion(
      battleId: battleId,
      title: title,
      summary: summary,
      participantCount: participantsCount,
      itemA: itemA, itemADesc: itemADesc, isCorrectA: isCorrectA,
      itemB: itemB, itemBDesc: itemBDesc, isCorrectB: isCorrectB
    )
  }
}

public extension VoteOptionDTO {
  func toDomain() -> VoteOption {
    VoteOption(label: label, title: title)
  }
}

public extension TodayVoteDTO {
  func toDomain() -> VoteQuestion {
    VoteQuestion(
      battleId: battleId,
      titlePrefix: titlePrefix,
      titleSuffix: titleSuffix,
      summary: summary,
      participantCount: participantsCount,
      options: options.map { $0.toDomain() }
    )
  }
}

public extension NewBattleDTO {
  func toDomain() -> NewBattle {
    NewBattle(
      battleId: battleId,
      thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
      title: title,
      summary: summary,
      philosopherA: philosopherA,
      optionATitle: optionATitle,
      philosopherAImageURL: philosopherAImageUrl.flatMap(URL.init(string:)),
      philosopherB: philosopherB,
      optionBTitle: optionBTitle,
      philosopherBImageURL: philosopherBImageUrl.flatMap(URL.init(string:)),
      tags: tags.map { $0.toDomain() },
      audioDuration: audioDuration,
      viewCount: viewCount
    )
  }
}

public extension HomeDataDTO {
  /// 전체 DTO 를 화면용 도메인 객체 6 묶음으로 변환.
  func toDomain() -> HomeBundle {
    HomeBundle(
      newNotice: newNotice,
      heroes: editorPicks.enumerated().map { idx, dto in
        dto.toDomain(position: idx + 1, total: editorPicks.count)
      },
      hotBattles: trendingBattles.map { $0.toDomain() },
      bestBattles: bestBattles.enumerated().map { idx, dto in
        dto.toDomain(rank: idx + 1)
      },
      quizzes: todayQuizzes.map { $0.toDomain() },
      votes: todayVotes.map { $0.toDomain() },
      newBattles: newBattles.map { $0.toDomain() }
    )
  }
}
