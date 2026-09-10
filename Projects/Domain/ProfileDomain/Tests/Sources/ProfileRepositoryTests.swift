//
//  ProfileRepositoryTests.swift
//  ProfileDataTests
//

import Foundation

import Dependencies
import Testing

@testable import ProfileDomain

import APIEndpoint
import ProfileDomainInterface

struct ProfileRepositoryTests {
  // MARK: - fetchMyPage

  @Test func fetchMyPage_은_응답을_MyPage_로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "profile": {
          "userTag": "picke1234",
          "nickname": "피클러",
          "characterType": "OWL",
          "characterLabel": "올빼미",
          "characterImageUrl": "https://picke.dev/owl.png",
          "mannerTemperature": 36.5
        },
        "philosopher": {
          "philosopherType": "SOCRATES",
          "philosopherLabel": "소크라테스형",
          "typeName": "질문형",
          "description": "끊임없이 질문하는 유형",
          "imageUrl": "https://picke.dev/socrates.png"
        },
        "tier": {
          "tierCode": "WANDERER",
          "tierLabel": "방랑자",
          "currentPoint": 120
        }
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.fetchMyPage()

    #expect(result.profile.userTag == "picke1234")
    #expect(result.profile.nickname == "피클러")
    #expect(result.profile.characterType == "OWL")
    #expect(result.profile.characterLabel == "올빼미")
    #expect(result.profile.characterImageURL == "https://picke.dev/owl.png")
    #expect(result.profile.mannerTemperature == 36.5)
    #expect(result.philosopher.philosopherType == "SOCRATES")
    #expect(result.philosopher.typeName == "질문형")
    #expect(result.tier.tierCode == "WANDERER")
    #expect(result.tier.currentPoint == 120)
  }

  @Test func fetchMyPage_은_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": {"code": "NOT_FOUND", "message": "마이페이지 없음"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 200,
      code: "NOT_FOUND",
      message: "마이페이지 없음"
    ) {
      try await repo.fetchMyPage()
    }
  }

  @Test func fetchMyPage_은_네트워크_계층_에러를_그대로_전파한다() async throws {
    let repo = withDependencies {
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      ProfileRepositoryImpl()
    }

    await #expect(throws: (any Error).self) {
      try await repo.fetchMyPage()
    }
  }

  // MARK: - updateProfile

  @Test func updateProfile_은_응답을_UpdatedProfile_로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "userTag": "picke1234",
        "nickname": "새 닉네임",
        "characterType": "OWL",
        "updatedAt": "2026-07-16T12:00:00Z"
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.updateProfile(
      nickname: "새 닉네임",
      characterType: "OWL"
    )

    #expect(result.userTag == "picke1234")
    #expect(result.nickname == "새 닉네임")
    #expect(result.characterType == "OWL")
    #expect(result.updatedAt == "2026-07-16T12:00:00Z")
  }

  @Test func updateProfile_은_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": {"code": "INVALID", "message": "프로필 수정 실패"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 200,
      code: "INVALID",
      message: "프로필 수정 실패"
    ) {
      try await repo.updateProfile(
        nickname: "새 닉네임",
        characterType: "OWL"
      )
    }
  }

  // MARK: - fetchRecap

  @Test func fetchRecap_은_응답을_PhilosopherRecap_으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "myCard": {
          "philosopherType": "KANT",
          "philosopherLabel": "칸트형",
          "typeName": "원칙형",
          "description": "원칙을 중시하는 유형",
          "keywordTags": ["#원칙", "#이성"],
          "imageUrl": "https://picke.dev/kant.png"
        },
        "bestMatchCard": {
          "philosopherType": "HUME",
          "philosopherLabel": "흄형",
          "typeName": "경험형",
          "description": "경험을 중시하는 유형",
          "keywordTags": ["#경험"],
          "imageUrl": "https://picke.dev/hume.png"
        },
        "worstMatchCard": {
          "philosopherType": "NIETZSCHE",
          "philosopherLabel": "니체형",
          "typeName": "개인형",
          "description": "개인을 중시하는 유형",
          "keywordTags": ["#개인"],
          "imageUrl": "https://picke.dev/nietzsche.png"
        },
        "scores": {
          "principle": 80.0,
          "reason": 70.0,
          "individual": 50.0,
          "change": 40.0,
          "inner": 60.0,
          "ideal": 90.0
        },
        "preferenceReport": {
          "totalParticipation": 12,
          "opinionChanges": 3,
          "battleWinRate": 66,
          "favoriteTopics": [
            {"rank": 1, "participationCount": 5, "tagName": "정치"}
          ]
        }
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.fetchRecap()

    #expect(result.myCard.philosopherType == "KANT")
    #expect(result.myCard.keywordTags == ["#원칙", "#이성"])
    #expect(result.bestMatchCard.philosopherType == "HUME")
    #expect(result.worstMatchCard.philosopherType == "NIETZSCHE")
    #expect(result.scores.principle == 80.0)
    #expect(result.scores.ideal == 90.0)
    #expect(result.preferenceReport.totalParticipation == 12)
    #expect(result.preferenceReport.battleWinRate == 66)
    #expect(result.preferenceReport.favoriteTopics.first?.tagName == "정치")
  }

  @Test func fetchRecap_은_200_data_nil이면_잠금용_empty_recap을_반환한다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": null}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.fetchRecap()

    #expect(result == .empty)
    #expect(result.preferenceReport.totalParticipation == 0)
    #expect(result.preferenceReport.totalParticipation < 5)
  }

  @Test func fetchRecap_은_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 500, "data": null, "error": {"code": "RECAP_FAILED", "message": "리캡 조회 실패"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8), statusCode: 500)
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 500,
      code: "RECAP_FAILED",
      message: "리캡 조회 실패"
    ) {
      try await repo.fetchRecap()
    }
  }

  // MARK: - fetchCreditHistory

  @Test func fetchCreditHistory_는_응답을_CreditHistoryPage_로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "id": 1,
            "creditType": "TODAY_CREDIT",
            "amount": 10,
            "referenceId": null,
            "createdAt": "2026-07-01T12:00:00Z"
          },
          {
            "id": 2,
            "creditType": "BATTLE_PARTICIPATION",
            "amount": -5,
            "referenceId": 42,
            "createdAt": "2026-07-02T09:30:00Z"
          }
        ],
        "nextOffset": 2,
        "hasNext": true
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.fetchCreditHistory(offset: 0, size: 20)

    #expect(result.items.count == 2)
    #expect(result.items[0].id == 1)
    #expect(result.items[0].creditType == "TODAY_CREDIT")
    #expect(result.items[0].amount == 10)
    #expect(result.items[0].referenceId == nil)
    #expect(result.items[0].createdAt != nil)
    #expect(result.items[1].referenceId == 42)
    #expect(result.items[1].amount == -5)
    #expect(result.nextOffset == 2)
    #expect(result.hasNext == true)
  }

  @Test func fetchCreditHistory_는_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": {"code": "ERR", "message": "크레딧 내역 없음"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 200,
      code: "ERR",
      message: "크레딧 내역 없음"
    ) {
      try await repo.fetchCreditHistory(offset: 0, size: 20)
    }
  }

  // MARK: - fetchBattleRecords

  @Test func fetchBattleRecords_는_응답을_BattleRecordPage_로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "battleId": "b1",
            "recordId": "r1",
            "voteSide": "PRO",
            "category": "정치",
            "title": "제목1",
            "summary": "요약1",
            "createdAt": "2026-07-01T12:00:00Z"
          }
        ],
        "nextOffset": 1,
        "hasNext": false
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.fetchBattleRecords(offset: 0, size: 20, voteSide: nil)

    #expect(result.items.count == 1)
    #expect(result.items[0].battleId == "b1")
    #expect(result.items[0].recordId == "r1")
    #expect(result.items[0].voteSide == .pro)
    #expect(result.items[0].category == "정치")
    #expect(result.items[0].categoryTag == "#정치")
    #expect(result.items[0].createdAt != nil)
    #expect(result.nextOffset == 1)
    #expect(result.hasNext == false)
  }

  @Test func fetchBattleRecords_는_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": {"code": "ERR", "message": "배틀 기록 없음"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 200,
      code: "ERR",
      message: "배틀 기록 없음"
    ) {
      try await repo.fetchBattleRecords(offset: 0, size: 20, voteSide: .pro)
    }
  }

  // MARK: - fetchContentActivities

  @Test func fetchContentActivities_는_응답을_ContentActivityPage_로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "activityId": "a1",
            "activityType": "COMMENT",
            "perspectiveId": "p1",
            "battleId": "b1",
            "battleTitle": "배틀제목",
            "author": {
              "userTag": "author1",
              "nickname": "작성자",
              "characterType": "OWL",
              "characterImageUrl": "https://picke.dev/owl.png"
            },
            "voteSide": "CON",
            "content": "내용입니다",
            "likeCount": 3,
            "createdAt": "2026-07-01T12:00:00Z"
          }
        ],
        "nextOffset": 1,
        "hasNext": false
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.fetchContentActivities(offset: 0, size: 20, activityType: nil)

    #expect(result.items.count == 1)
    #expect(result.items[0].activityId == "a1")
    #expect(result.items[0].activityType == .comment)
    #expect(result.items[0].author.nickname == "작성자")
    #expect(result.items[0].voteSide == .con)
    #expect(result.items[0].stanceText == "반대의견")
    #expect(result.items[0].likeCount == 3)
    #expect(result.nextOffset == 1)
    #expect(result.hasNext == false)
  }

  @Test func fetchContentActivities_는_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": {"code": "ERR", "message": "콘텐츠 활동 없음"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 200,
      code: "ERR",
      message: "콘텐츠 활동 없음"
    ) {
      try await repo.fetchContentActivities(offset: 0, size: 20, activityType: .comment)
    }
  }

  // MARK: - fetchNotificationSettings

  @Test func fetchNotificationSettings_는_응답을_NotificationSettings_로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "newBattleEnabled": true,
        "battleResultEnabled": false,
        "commentReplyEnabled": true,
        "newCommentEnabled": false,
        "contentLikeEnabled": true,
        "marketingEventEnabled": false
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.fetchNotificationSettings()

    #expect(result.newBattleEnabled == true)
    #expect(result.battleResultEnabled == false)
    #expect(result.commentReplyEnabled == true)
    #expect(result.newCommentEnabled == false)
    #expect(result.contentLikeEnabled == true)
    #expect(result.marketingEventEnabled == false)
  }

  @Test func fetchNotificationSettings_는_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": {"code": "ERR", "message": "알림 설정 없음"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 200,
      code: "ERR",
      message: "알림 설정 없음"
    ) {
      try await repo.fetchNotificationSettings()
    }
  }

  // MARK: - updateNotificationSettings

  @Test func updateNotificationSettings_는_응답을_NotificationSettings_로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "newBattleEnabled": false,
        "battleResultEnabled": true,
        "commentReplyEnabled": false,
        "newCommentEnabled": true,
        "contentLikeEnabled": false,
        "marketingEventEnabled": true
      },
      "error": null
    }
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    let result = try await repo.updateNotificationSettings(NotificationSettings())

    #expect(result.newBattleEnabled == false)
    #expect(result.battleResultEnabled == true)
    #expect(result.commentReplyEnabled == false)
    #expect(result.newCommentEnabled == true)
    #expect(result.contentLikeEnabled == false)
    #expect(result.marketingEventEnabled == true)
  }

  @Test func updateNotificationSettings_는_error_봉투이면_네트워크_response_에러를_던진다() async throws {
    let json = """
    {"statusCode": 200, "data": null, "error": {"code": "ERR", "message": "알림 설정 갱신 실패"}}
    """
    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: Data(json.utf8))
    } operation: {
      ProfileRepositoryImpl()
    }

    await expectNetworkResponseError(
      statusCode: 200,
      code: "ERR",
      message: "알림 설정 갱신 실패"
    ) {
      try await repo.updateNotificationSettings(NotificationSettings())
    }
  }
}
