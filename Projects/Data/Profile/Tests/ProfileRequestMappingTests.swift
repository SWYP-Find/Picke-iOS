//
//  ProfileRequestMappingTests.swift
//  ProfileDataTests
//

import Foundation
import Testing

@testable import ProfileData

import NetworkHeader
import Service

struct ProfileRequestMappingTests {
  @Test func mypage_요청은_GET_이며_경로가_api_v1_me_mypage_이다() throws {
    let request = try ProfileService.mypage.asURLRequest()

    #expect(request.url?.path == "/api/v1/me/mypage")
    #expect(request.httpMethod == "GET")
    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  @Test func recap_요청은_GET_이며_경로가_api_v1_me_recap_이다() throws {
    let request = try ProfileService.recap.asURLRequest()

    #expect(request.url?.path == "/api/v1/me/recap")
    #expect(request.httpMethod == "GET")
    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  @Test func creditsHistory_요청은_GET_이며_쿼리스트링으로_offset_size_를_전달한다() throws {
    let query = CreditHistoryQueryRequest(offset: 0, size: 20)
    let request = try ProfileService.creditsHistory(query: query).asURLRequest()

    #expect(request.url?.path == "/api/v1/me/credits/history")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)

    let queryString = try #require(request.url?.query)
    #expect(queryString.contains("offset=0"))
    #expect(queryString.contains("size=20"))
  }

  @Test func battleRecords_요청은_GET_이며_쿼리스트링으로_offset_size_voteSide_를_전달한다() throws {
    let query = BattleRecordsQueryRequest(offset: 10, size: 20, voteSide: "PRO")
    let request = try ProfileService.battleRecords(query: query).asURLRequest()

    #expect(request.url?.path == "/api/v1/me/battle-records")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)

    let queryString = try #require(request.url?.query)
    #expect(queryString.contains("offset=10"))
    #expect(queryString.contains("size=20"))
    #expect(queryString.contains("vote_side=PRO"))
  }

  @Test func battleRecords_요청은_voteSide_가_nil_이면_vote_side_파라미터를_생략한다() throws {
    let query = BattleRecordsQueryRequest(offset: 0, size: 20, voteSide: nil)
    let request = try ProfileService.battleRecords(query: query).asURLRequest()

    let queryString = try #require(request.url?.query)
    #expect(!queryString.contains("vote_side"))
  }

  @Test func contentActivities_요청은_GET_이며_쿼리스트링으로_offset_size_activityType_를_전달한다() throws {
    let query = ContentActivitiesQueryRequest(offset: 0, size: 20, activityType: "COMMENT")
    let request = try ProfileService.contentActivities(query: query).asURLRequest()

    #expect(request.url?.path == "/api/v1/me/content-activities")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)

    let queryString = try #require(request.url?.query)
    #expect(queryString.contains("offset=0"))
    #expect(queryString.contains("size=20"))
    #expect(queryString.contains("activity_type=COMMENT"))
  }

  @Test func notificationSettings_요청은_GET_이며_경로가_api_v1_me_notification_settings_이다() throws {
    let request = try ProfileService.notificationSettings.asURLRequest()

    #expect(request.url?.path == "/api/v1/me/notification-settings")
    #expect(request.httpMethod == "GET")
    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  @Test func updateNotificationSettings_요청은_PATCH_이며_JSON_바디로_6개_토글을_전달한다() throws {
    let body = NotificationSettingsRequest(
      newBattleEnabled: true,
      battleResultEnabled: false,
      commentReplyEnabled: true,
      newCommentEnabled: false,
      contentLikeEnabled: true,
      marketingEventEnabled: false
    )
    let request = try ProfileService.updateNotificationSettings(body: body).asURLRequest()

    #expect(request.url?.path == "/api/v1/me/notification-settings")
    #expect(request.httpMethod == "PATCH")
    #expect(request.url?.query == nil)

    let httpBody = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: httpBody) as? [String: Any])
    #expect(json["newBattleEnabled"] as? Bool == true)
    #expect(json["battleResultEnabled"] as? Bool == false)
    #expect(json["commentReplyEnabled"] as? Bool == true)
    #expect(json["newCommentEnabled"] as? Bool == false)
    #expect(json["contentLikeEnabled"] as? Bool == true)
    #expect(json["marketingEventEnabled"] as? Bool == false)
  }

  @Test func 모든_요청은_baseHeader_를_포함한다() throws {
    let request = try ProfileService.mypage.asURLRequest()

    #expect(request.value(forHTTPHeaderField: "Content-Type") != nil)
    #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer") == true)
  }
}
