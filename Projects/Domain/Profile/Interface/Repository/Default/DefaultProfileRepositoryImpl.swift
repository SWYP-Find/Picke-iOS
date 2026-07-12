//
//  DefaultProfileRepositoryImpl.swift
//  DomainInterface
//

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

  public func fetchRecap() async throws -> PhilosopherRecap {
    PhilosopherRecap(
      myCard: RecapCard(
        philosopherType: "",
        philosopherLabel: "",
        typeName: "",
        description: "",
        keywordTags: [],
        imageURL: ""
      ),
      bestMatchCard: RecapCard(
        philosopherType: "",
        philosopherLabel: "",
        typeName: "",
        description: "",
        keywordTags: [],
        imageURL: ""
      ),
      worstMatchCard: RecapCard(
        philosopherType: "",
        philosopherLabel: "",
        typeName: "",
        description: "",
        keywordTags: [],
        imageURL: ""
      ),
      scores: RecapScores(
        principle: 0,
        reason: 0,
        individual: 0,
        change: 0,
        inner: 0,
        ideal: 0
      ),
      preferenceReport: PreferenceReport(
        totalParticipation: 0,
        opinionChanges: 0,
        battleWinRate: 0,
        favoriteTopics: []
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

  public func fetchNotificationSettings() async throws -> NotificationSettings {
    NotificationSettings()
  }

  public func updateNotificationSettings(_: NotificationSettings) async throws -> NotificationSettings {
    NotificationSettings()
  }
}
