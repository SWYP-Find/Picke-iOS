//
//  BattleRequestMappingTests.swift
//  BattleDataTests
//

import Testing

@testable import BattleDomain

import APIEndpoint
import Foundation
@testable import PickeNetwork

struct BattleRequestMappingTests {
  // MARK: - today

  @Test func today_요청은_GET_이며_경로가_api_v1_battles_today_이다() throws {
    let request = try BattleService.today.asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/today")
    #expect(request.httpMethod == "GET")
    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  // MARK: - detail

  @Test func detail_요청은_GET_이며_경로에_battleId_가_포함된다() throws {
    let request = try BattleService.detail(battleId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)
  }

  // MARK: - preVote

  @Test func preVote_요청은_POST_이며_경로가_votes_pre_이고_JSON_바디에_optionId_를_담는다() throws {
    let request = try BattleService.preVote(
      battleId: 42,
      body: PreVoteRequest(optionId: 7)
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/votes/pre")
    #expect(request.httpMethod == "POST")

    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["optionId"] as? Int == 7)
  }

  // MARK: - postVote

  @Test func postVote_요청은_POST_이며_경로가_votes_post_이고_JSON_바디에_optionId_를_담는다() throws {
    let request = try BattleService.postVote(
      battleId: 42,
      body: PreVoteRequest(optionId: 3)
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/votes/post")
    #expect(request.httpMethod == "POST")

    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["optionId"] as? Int == 3)
  }

  // MARK: - scenario

  @Test func scenario_요청은_GET_이며_경로가_scenario_이다() throws {
    let request = try BattleService.scenario(battleId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/scenario")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)
  }

  // MARK: - voteStats

  @Test func voteStats_요청은_GET_이며_경로가_vote_stats_이다() throws {
    let request = try BattleService.voteStats(battleId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/vote-stats")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)
  }

  // MARK: - perspectives (query)

  @Test func perspectives_요청은_GET_이며_쿼리파라미터를_URL_에_담는다() throws {
    let request = try BattleService.perspectives(
      battleId: 42,
      query: PerspectivesQueryRequest(cursor: "abc", size: 20, optionId: 1, sort: "popular")
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/perspectives")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)

    let query = try #require(request.url?.query)
    #expect(query.contains("cursor=abc"))
    #expect(query.contains("size=20"))
    #expect(query.contains("optionId=1"))
    #expect(query.contains("sort=popular"))
  }

  @Test func perspectives_요청은_쿼리파라미터가_모두_nil_이면_쿼리스트링이_없다() throws {
    let request = try BattleService.perspectives(
      battleId: 42,
      query: PerspectivesQueryRequest()
    ).asURLRequest()

    #expect(request.url?.query == nil)
  }

  // MARK: - createPerspective (JSON body)

  @Test func createPerspective_요청은_POST_이며_경로가_perspectives_이고_JSON_바디에_content_optionId_를_담는다() throws {
    let request = try BattleService.createPerspective(
      battleId: 42,
      body: CreatePerspectiveRequest(content: "내 의견입니다", optionId: 1)
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/perspectives")
    #expect(request.httpMethod == "POST")

    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["content"] as? String == "내 의견입니다")
    #expect(json["optionId"] as? Int == 1)
  }

  @Test func createPerspective_요청은_optionId_가_nil_이면_JSON_바디에_키가_없다() throws {
    let request = try BattleService.createPerspective(
      battleId: 42,
      body: CreatePerspectiveRequest(content: "내 의견입니다")
    ).asURLRequest()

    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["content"] as? String == "내 의견입니다")
    #expect(json["optionId"] == nil)
  }

  // MARK: - myPerspective

  @Test func myPerspective_요청은_GET_이며_경로가_perspectives_me_이다() throws {
    let request = try BattleService.myPerspective(battleId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/perspectives/me")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)
  }

  // MARK: - recommendations

  @Test func recommendations_요청은_GET_이며_경로가_recommendations_interesting_이다() throws {
    let request = try BattleService.recommendations(battleId: 42).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/42/recommendations/interesting")
    #expect(request.httpMethod == "GET")
    #expect(request.httpBody == nil)
  }

  // MARK: - createProposal (JSON body)

  @Test func createProposal_요청은_POST_이며_경로가_proposals_이고_JSON_바디에_모든_필드를_담는다() throws {
    let request = try BattleService.createProposal(
      body: BattleProposalRequest(
        category: "철학",
        topic: "AI는 의식이 있는가",
        positionA: "있다",
        positionB: "없다",
        description: "설명"
      )
    ).asURLRequest()

    #expect(request.url?.path == "/api/v1/battles/proposals")
    #expect(request.httpMethod == "POST")

    let body = try #require(request.httpBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["category"] as? String == "철학")
    #expect(json["topic"] as? String == "AI는 의식이 있는가")
    #expect(json["positionA"] as? String == "있다")
    #expect(json["positionB"] as? String == "없다")
    #expect(json["description"] as? String == "설명")
  }

  // MARK: - headers

  @Test func 모든_요청은_자동_인증_정책을_사용한다() {
    let services: [BattleService] = [
      .today,
      .detail(battleId: 42),
      .preVote(battleId: 42, body: PreVoteRequest(optionId: 1)),
      .postVote(battleId: 42, body: PreVoteRequest(optionId: 1)),
      .scenario(battleId: 42),
      .voteStats(battleId: 42),
      .perspectives(battleId: 42, query: PerspectivesQueryRequest()),
      .createPerspective(battleId: 42, body: CreatePerspectiveRequest(content: "내용")),
      .myPerspective(battleId: 42),
      .recommendations(battleId: 42),
      .createProposal(
        body: BattleProposalRequest(
          category: "철학",
          topic: "AI",
          positionA: "있다",
          positionB: "없다",
          description: "설명"
        )
      ),
    ]

    for service in services {
      #expect(service.authorization == .automatic)
    }
  }
}
