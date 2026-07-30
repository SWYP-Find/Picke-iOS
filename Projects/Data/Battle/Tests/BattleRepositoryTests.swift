//
//  BattleRepositoryTests.swift
//  BattleDataTests
//

import Testing

@testable import BattleData

import BattleDomainInterface
import CommonDomainInterface
import Foundation
import HomeDomainInterface

struct BattleRepositoryTests {
  // MARK: - fetchTodayBattles

  @Test func fetchTodayBattles_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "battleId": 1,
            "title": "오늘의 배틀",
            "summary": "요약",
            "thumbnailUrl": "https://img.picke.app/1.png",
            "viewCount": 100,
            "participantsCount": 10,
            "audioDuration": 120,
            "tags": [{"tagId": 1, "name": "철학", "type": "CATEGORY"}],
            "options": [
              {"optionId": 1, "label": "A", "title": "찬성", "stance": "PRO", "representative": "소크라테스", "imageUrl": "https://img.picke.app/a.png", "tags": []}
            ]
          }
        ],
        "totalCount": 1
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let page = try await repo.fetchTodayBattles()

    #expect(page.totalCount == 1)
    #expect(page.items.count == 1)
    #expect(page.items[0].battleId == 1)
    #expect(page.items[0].tags[0].type == .category)
    #expect(page.items[0].options[0].label == "A")
  }

  @Test func fetchTodayBattles_는_items_가_빈배열이어도_성공한다() async throws {
    let json = """
    { "statusCode": 200, "data": { "items": [], "totalCount": 0 }, "error": null }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let page = try await repo.fetchTodayBattles()

    #expect(page.items.isEmpty)
    #expect(page.totalCount == 0)
  }

  @Test func fetchTodayBattles_는_data_가_nil_이면_backendError_를_던진다() async throws {
    let json = """
    { "statusCode": 400, "data": null, "error": {"code": "BAD_REQUEST", "message": "오늘의 배틀 조회 실패"} }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    do {
      _ = try await repo.fetchTodayBattles()
      Issue.record("에러가 발생해야 한다")
    } catch let error as BattleError {
      guard case let .backendError(message) = error else {
        Issue.record("backendError 여야 한다: \(error)")
        return
      }
      #expect(message == "오늘의 배틀 조회 실패")
    }
  }

  // MARK: - fetchBattle

  @Test func fetchBattle_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "battleInfo": {
          "battleId": 1,
          "title": "배틀 제목",
          "summary": "요약",
          "thumbnailUrl": "https://img.picke.app/1.png",
          "viewCount": 100,
          "participantsCount": 10,
          "audioDuration": 120,
          "tags": [],
          "options": []
        },
        "description": "설명",
        "shareUrl": "https://picke.app/share/1",
        "userVoteStatus": "PRO",
        "currentStep": "PRE_VOTE",
        "categoryTags": [{"tagId": 2, "name": "카테고리", "type": "CATEGORY"}],
        "philosopherTags": [],
        "valueTags": []
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let detail = try await repo.fetchBattle(battleId: 1)

    #expect(detail.id == 1)
    #expect(detail.userVoteStatus == .pro)
    #expect(detail.currentStep == .preVote)
    #expect(detail.categoryTags.count == 1)
  }

  // MARK: - submitPreVote

  @Test func submitPreVote_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    { "statusCode": 200, "data": {"voteId": 10, "status": "CREATED"}, "error": null }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let result = try await repo.submitPreVote(battleId: 1, optionId: 7)

    #expect(result.voteId == 10)
    #expect(result.status == .created)
  }

  // MARK: - submitPostVote

  @Test func submitPostVote_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    { "statusCode": 200, "data": {"voteId": 11, "status": "UPDATED"}, "error": null }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let result = try await repo.submitPostVote(battleId: 1, optionId: 3)

    #expect(result.voteId == 11)
    #expect(result.status == .updated)
  }

  // MARK: - fetchVoteStats

  @Test func fetchVoteStats_는_100_초과_ratio_를_비율로_정규화한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "options": [
          {"optionId": 1, "label": "A", "title": "찬성", "isCorrect": true, "voteCount": 45, "ratio": 45.0, "stance": "PRO", "imageUrl": "https://img.picke.app/a.png"},
          {"optionId": 2, "label": "B", "title": "반대", "isCorrect": false, "voteCount": 55, "ratio": 0.55, "stance": "CON", "imageUrl": "https://img.picke.app/b.png"}
        ],
        "totalCount": 100,
        "updatedAt": "2026-05-22T13:28:16.697Z"
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let stats = try await repo.fetchVoteStats(battleId: 1)

    #expect(stats.totalCount == 100)
    #expect(stats.options[0].ratio == 0.45)
    #expect(stats.options[1].ratio == 0.55)
    #expect(stats.updatedAt != nil)
  }

  // MARK: - fetchPerspectives

  @Test func fetchPerspectives_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "perspectiveId": 1,
            "user": {"userTag": "#123", "nickname": "철수", "characterType": "SOCRATES", "characterImageUrl": "https://img.picke.app/u.png"},
            "option": {"optionId": 1, "label": "A", "title": "찬성", "stance": "PRO"},
            "content": "내용",
            "likeCount": 5,
            "commentCount": 2,
            "isLiked": true,
            "isMyPerspective": false,
            "createdAt": "2026-05-22T13:28:16.697Z"
          }
        ],
        "nextCursor": "cursor123",
        "hasNext": true
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let page = try await repo.fetchPerspectives(battleId: 1, cursor: nil, size: nil, optionId: nil, sort: nil)

    #expect(page.hasNext == true)
    #expect(page.nextCursor == "cursor123")
    #expect(page.items[0].isLiked == true)
    #expect(page.items[0].createdAt != nil)
  }

  @Test func fetchPerspectives_는_items_가_빈배열이어도_성공한다() async throws {
    let json = """
    { "statusCode": 200, "data": {"items": [], "nextCursor": null, "hasNext": false}, "error": null }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let page = try await repo.fetchPerspectives(battleId: 1, cursor: nil, size: nil, optionId: nil, sort: .popular)

    #expect(page.items.isEmpty)
    #expect(page.hasNext == false)
  }

  // MARK: - createPerspective

  // createPerspective 는 생성 응답 확인 후 fetchMyPerspective 를 재호출한다.
  // StubNetworkProvider 는 요청 target 과 무관하게 동일한 stubData 를 디코딩하므로,
  // 이 fixture 는 CreatePerspectiveDataDTO(perspectiveId/status/createdAt) 와
  // BattlePerspectiveDTO(perspectiveId/user/option/content/likeCount/commentCount/...) 양쪽 모두를
  // 디코딩할 수 있도록 두 DTO 의 필드를 모두 포함한다.

  @Test func createPerspective_는_생성_후_myPerspective_재조회_결과를_반환한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 5,
        "status": "CREATED",
        "createdAt": "2026-05-22T13:28:16.697Z",
        "user": {"userTag": "#123", "nickname": "철수", "characterType": "SOCRATES", "characterImageUrl": null},
        "option": {"optionId": 1, "label": "A", "title": "찬성", "stance": "PRO"},
        "content": "내 의견입니다",
        "likeCount": 0,
        "commentCount": 0,
        "isLiked": false,
        "isMyPerspective": true
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let perspective = try await repo.createPerspective(battleId: 1, content: "내 의견입니다", optionId: 1)

    #expect(perspective?.perspectiveId == 5)
    #expect(perspective?.content == "내 의견입니다")
    #expect(perspective?.isMyPerspective == true)
  }

  // 실제 서버 응답에는 user/option 이 없어 재조회(BattlePerspectiveDTO) 디코딩이 실패한다.
  // 등록 자체는 성공했으므로 throw 하지 않고 nil 을 돌려줘야 호출부가 목록을 갱신할 수 있다.
  @Test func createPerspective_는_재조회_실패해도_던지지_않고_nil_을_반환한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 249,
        "status": "PUBLISHED",
        "createdAt": "2026-07-29T23:35:39.593249513"
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let perspective = try await repo.createPerspective(battleId: 39, content: "ㄴㄴㄴ", optionId: 75)

    #expect(perspective == nil)
  }

  @Test func createPerspective_는_data_가_nil_이면_backendError_를_던진다() async throws {
    let json = """
    { "statusCode": 400, "data": null, "error": {"code": "BAD_REQUEST", "message": "댓글 작성 실패"} }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    do {
      _ = try await repo.createPerspective(battleId: 1, content: "내용", optionId: nil)
      Issue.record("에러가 발생해야 한다")
    } catch let error as BattleError {
      guard case let .backendError(message) = error else {
        Issue.record("backendError 여야 한다: \(error)")
        return
      }
      #expect(message == "댓글 작성 실패")
    }
  }

  // MARK: - fetchMyPerspective

  @Test func fetchMyPerspective_는_참여_이력이_있으면_도메인을_반환한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "perspectiveId": 9,
        "user": {"userTag": "#1", "nickname": "영희", "characterType": "PLATO", "characterImageUrl": null},
        "option": {"optionId": 2, "label": "B", "title": "반대", "stance": "CON"},
        "content": "내 관점",
        "likeCount": 1,
        "commentCount": 0,
        "isLiked": false,
        "isMyPerspective": true,
        "createdAt": "2026-05-22T13:28:16.697Z"
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let perspective = try await repo.fetchMyPerspective(battleId: 1)

    #expect(perspective?.perspectiveId == 9)
  }

  @Test func fetchMyPerspective_는_statusCode_가_400_이상이면_nil_을_반환한다() async throws {
    let json = """
    { "statusCode": 404, "data": null, "error": {"code": "NOT_FOUND", "message": "참여 이력 없음"} }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let perspective = try await repo.fetchMyPerspective(battleId: 1)

    #expect(perspective == nil)
  }

  @Test func fetchMyPerspective_는_provider_가_에러를_던지면_nil_을_반환한다() async throws {
    let repo = BattleRepositoryImpl(provider: ThrowingStubNetworkProvider<BattleService>())

    let perspective = try await repo.fetchMyPerspective(battleId: 1)

    #expect(perspective == nil)
  }

  // MARK: - fetchScenario

  @Test func fetchScenario_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "battleId": 1,
        "title": "시나리오 제목",
        "philosophers": [{"label": "A", "name": "소크라테스", "stance": "PRO", "imageUrl": "https://img.picke.app/s.png"}],
        "isInteractive": true,
        "startNodeId": 100,
        "recommendedPathKey": "COMMON",
        "audios": {"100": "https://audio.picke.app/100.mp3"},
        "nodes": [
          {
            "nodeId": 100,
            "nodeName": "시작",
            "audioDuration": 30,
            "autoNextNodeId": 101,
            "scripts": [{"scriptId": 1, "startTimeMs": 0, "speakerType": "NARRATOR", "speakerName": "내레이터", "text": "안녕하세요"}],
            "interactiveOptions": [{"label": "찬성", "nextNodeId": 101}]
          }
        ]
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let scenario = try await repo.fetchScenario(battleId: 1)

    #expect(scenario.recommendedPathKey == .common)
    #expect(scenario.philosophers[0].label == "A")
    #expect(scenario.nodes[0].scripts[0].speakerType == .narrator)
    #expect(scenario.nodes[0].interactiveOptions[0].nextNodeId == 101)
  }

  @Test func fetchScenario_는_philosopher_label_이_없으면_인덱스_기반_폴백_라벨을_사용한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "battleId": 1,
        "title": "시나리오 제목",
        "philosophers": [
          {"name": "소크라테스", "stance": "PRO", "imageUrl": "https://img.picke.app/s.png"},
          {"name": "플라톤", "stance": "CON", "imageUrl": "https://img.picke.app/p.png"}
        ],
        "isInteractive": false,
        "startNodeId": 100,
        "recommendedPathKey": "COMMON",
        "audios": {},
        "nodes": []
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let scenario = try await repo.fetchScenario(battleId: 1)

    #expect(scenario.philosophers[0].label == "A")
    #expect(scenario.philosophers[1].label == "B")
  }

  // MARK: - fetchRecommendedBattles

  @Test func fetchRecommendedBattles_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "battleId": 2,
            "title": "추천 배틀",
            "summary": "요약",
            "audioDuration": 60,
            "viewCount": 50,
            "tags": [{"tagId": 1, "name": "철학"}],
            "participantsCount": 5,
            "options": [{"optionId": 1, "title": "찬성", "stance": "PRO", "representative": "소크라테스", "imageUrl": "https://img.picke.app/r.png"}]
          }
        ],
        "nextCursor": null,
        "hasNext": false
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let page = try await repo.fetchRecommendedBattles(battleId: 1)

    #expect(page.items[0].battleId == 2)
    #expect(page.hasNext == false)
    #expect(page.nextCursor == nil)
  }

  @Test func fetchRecommendedBattles_는_옵셔널_필드가_모두_nil_이어도_기본값으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [{"battleId": 3}],
        "nextCursor": null,
        "hasNext": false
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))

    let page = try await repo.fetchRecommendedBattles(battleId: 1)

    #expect(page.items[0].battleId == 3)
    #expect(page.items[0].title == "")
    #expect(page.items[0].tags.isEmpty)
    #expect(page.items[0].options.isEmpty)
  }

  // MARK: - proposeBattle

  @Test func proposeBattle_는_봉투_data_를_도메인으로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "id": 10,
        "userId": 5,
        "nickname": "철수",
        "category": "철학",
        "topic": "AI는 의식이 있는가",
        "positionA": "있다",
        "positionB": "없다",
        "description": "설명",
        "status": "PENDING",
        "createdAt": "2026-05-22T13:28:16.697Z"
      },
      "error": null
    }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))
    let draft = BattleProposalDraft(
      category: "철학",
      topic: "AI는 의식이 있는가",
      positionA: "있다",
      positionB: "없다",
      description: "설명"
    )

    let proposal = try await repo.proposeBattle(draft)

    #expect(proposal.id == 10)
    #expect(proposal.status == "PENDING")
    #expect(proposal.createdAt != nil)
  }

  @Test func proposeBattle_는_data_가_nil_이면_backendError_를_던진다() async throws {
    let json = """
    { "statusCode": 400, "data": null, "error": {"code": "BAD_REQUEST", "message": "배틀 제안 실패"} }
    """
    let repo = BattleRepositoryImpl(provider: StubNetworkProvider<BattleService>(stubData: Data(json.utf8)))
    let draft = BattleProposalDraft(
      category: "철학",
      topic: "주제",
      positionA: "A",
      positionB: "B",
      description: "설명"
    )

    do {
      _ = try await repo.proposeBattle(draft)
      Issue.record("에러가 발생해야 한다")
    } catch let error as BattleError {
      guard case let .backendError(message) = error else {
        Issue.record("backendError 여야 한다: \(error)")
        return
      }
      #expect(message == "배틀 제안 실패")
    }
  }
}
