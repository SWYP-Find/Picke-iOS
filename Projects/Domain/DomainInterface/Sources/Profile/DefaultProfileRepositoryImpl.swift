//
//  DefaultProfileRepositoryImpl.swift
//  DomainInterface
//

import Entity
import Foundation

public struct DefaultProfileRepositoryImpl: ProfileInterface {
  public init() {}

  public func fetchMyPage() async throws -> MyPage {
    MyPage(
      profile: MyProfile(
        userTag: "",
        nickname: "",
        characterType: "",
        characterLabel: "",
        characterImageURL: "",
        mannerTemperature: 0
      ),
      philosopher: MyPhilosopher(
        philosopherType: "",
        philosopherLabel: "",
        typeName: "",
        description: "",
        imageURL: ""
      ),
      tier: MyTier(
        tierCode: "",
        tierLabel: "",
        currentPoint: 0
      )
    )
  }

  public func fetchCreditHistory(
    offset _: Int,
    size _: Int
  ) async throws -> CreditHistoryPage {
    CreditHistoryPage(items: [], nextOffset: 0, hasNext: false)
  }

  public func fetchBattleRecords(
    offset _: Int,
    size _: Int,
    voteSide _: BattleVoteSide?
  ) async throws -> BattleRecordPage {
    BattleRecordPage(items: [], nextOffset: 0, hasNext: false)
  }

  public func fetchContentActivities(
    offset _: Int,
    size _: Int,
    activityType _: ContentActivityType?
  ) async throws -> ContentActivityPage {
    ContentActivityPage(items: [], nextOffset: 0, hasNext: false)
  }
}
