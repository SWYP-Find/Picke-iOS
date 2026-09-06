//
//  HomeRepositoryTests.swift
//  HomeDataTests
//

import Foundation
import Testing

@testable import HomeData

import APIEndpoint
import AuthDomainInterface
import HomeDomainInterface

struct HomeRepositoryTests {
  private static let fullEnvelope = """
  {
    "statusCode": 200,
    "data": {
      "newNotice": true,
      "editorPicks": [
        {
          "battleId": 1,
          "thumbnailUrl": "https://example.com/thumb1.png",
          "optionATitle": "예술이다",
          "optionBTitle": "쓰레기다",
          "title": "뒤샹의 변기, 예술인가 도발인가",
          "summary": "무엇이 예술인가",
          "tags": [
            { "tagId": 1, "name": "#예술", "type": "CATEGORY" }
          ],
          "viewCount": 847
        }
      ],
      "trendingBattles": [
        {
          "battleId": 11,
          "thumbnailUrl": null,
          "title": "인간은 본래 선한가",
          "tags": [
            { "tagId": 301, "name": "#철학", "type": "CATEGORY" }
          ],
          "audioDuration": 480,
          "viewCount": 1340
        }
      ],
      "bestBattles": [
        {
          "battleId": 21,
          "philosopherA": "맹자",
          "philosopherB": "순자",
          "title": "인간은 본래 선한가",
          "tags": [
            { "tagId": 401, "name": "#철학", "type": "CATEGORY" }
          ],
          "audioDuration": 480,
          "viewCount": 1340
        },
        {
          "battleId": 22,
          "philosopherA": "칸트",
          "philosopherB": "톨스토이",
          "title": "진실을 말해야 하는가",
          "tags": [],
          "audioDuration": 480,
          "viewCount": 900
        }
      ],
      "todayQuizzes": [
        {
          "battleId": 31,
          "title": "AI가 만든 그림도 예술인가",
          "summary": "당신의 입장을 선택하세요",
          "participantsCount": 1340,
          "itemA": "O 정답",
          "itemADesc": "explanation A",
          "isCorrectA": true,
          "itemB": "X 오답",
          "itemBDesc": "explanation B",
          "isCorrectB": false
        }
      ],
      "todayVotes": [
        {
          "battleId": 41,
          "titlePrefix": "도덕의 기준은",
          "titleSuffix": "이다",
          "summary": "빈칸에 들어갈 답을 골라주세요",
          "participantsCount": 985,
          "options": [
            { "label": "A", "title": "결과" },
            { "label": "B", "title": "의도" }
          ]
        }
      ],
      "newBattles": [
        {
          "battleId": 51,
          "thumbnailUrl": "https://example.com/new1.png",
          "title": "노키즈존, 영업의 자유인가",
          "summary": "울음소리가 휴식을 깨뜨린다면",
          "philosopherA": "순자",
          "optionATitle": "악하다",
          "philosopherAImageUrl": null,
          "philosopherB": "맹자",
          "optionBTitle": "선하다",
          "philosopherBImageUrl": "https://example.com/philo-b.png",
          "tags": [
            { "tagId": 501, "name": "#사회", "type": "CATEGORY" }
          ],
          "audioDuration": 300,
          "viewCount": 726
        }
      ]
    },
    "error": null
  }
  """

  private static let emptyEnvelope = """
  {
    "statusCode": 200,
    "data": {
      "newNotice": false,
      "editorPicks": [],
      "trendingBattles": [],
      "bestBattles": [],
      "todayQuizzes": [],
      "todayVotes": [],
      "newBattles": []
    },
    "error": null
  }
  """

  private static let emptyDataEnvelope = """
  {
    "statusCode": 500,
    "data": null,
    "error": { "code": "HOME_500", "message": "홈 데이터를 불러오지 못했습니다" }
  }
  """

  @Test func fetchHome_성공시_도메인_번들로_매핑된다() async throws {
    let data = try #require(Self.fullEnvelope.data(using: .utf8))
    let repository = HomeRepositoryImpl(provider: StubNetworkProvider<HomeService>(stubData: data))

    let bundle = try await repository.fetchHome()

    #expect(bundle.newNotice == true)

    #expect(bundle.heroes.count == 1)
    #expect(bundle.heroes[0].battleId == 1)
    #expect(bundle.heroes[0].position == 1)
    #expect(bundle.heroes[0].total == 1)
    #expect(bundle.heroes[0].optionA == "예술이다")
    #expect(bundle.heroes[0].optionB == "쓰레기다")
    #expect(bundle.heroes[0].tags == [BattleTag(tagId: 1, name: "#예술", type: .category)])

    #expect(bundle.hotBattles.count == 1)
    #expect(bundle.hotBattles[0].battleId == 11)
    #expect(bundle.hotBattles[0].thumbnailURL == nil)

    #expect(bundle.bestBattles.count == 2)
    #expect(bundle.bestBattles[0].rank == 1)
    #expect(bundle.bestBattles[0].battleId == 21)
    #expect(bundle.bestBattles[1].rank == 2)
    #expect(bundle.bestBattles[1].battleId == 22)
    #expect(bundle.bestBattles[1].tags.isEmpty)

    #expect(bundle.quizzes.count == 1)
    #expect(bundle.quizzes[0].isCorrectA == true)
    #expect(bundle.quizzes[0].isCorrectB == false)

    #expect(bundle.votes.count == 1)
    #expect(bundle.votes[0].options == [
      VoteOption(label: "A", title: "결과"),
      VoteOption(label: "B", title: "의도"),
    ])

    #expect(bundle.newBattles.count == 1)
    #expect(bundle.newBattles[0].philosopherAImageURL == nil)
    #expect(bundle.newBattles[0].philosopherBImageURL == URL(string: "https://example.com/philo-b.png"))
  }

  @Test func fetchHome_빈_섹션이면_빈_배열로_매핑된다() async throws {
    let data = try #require(Self.emptyEnvelope.data(using: .utf8))
    let repository = HomeRepositoryImpl(provider: StubNetworkProvider<HomeService>(stubData: data))

    let bundle = try await repository.fetchHome()

    #expect(bundle.newNotice == false)
    #expect(bundle.heroes.isEmpty)
    #expect(bundle.hotBattles.isEmpty)
    #expect(bundle.bestBattles.isEmpty)
    #expect(bundle.quizzes.isEmpty)
    #expect(bundle.votes.isEmpty)
    #expect(bundle.newBattles.isEmpty)
  }

  @Test func fetchHome_data가_비어있으면_backendError_를_던진다() async throws {
    let data = try #require(Self.emptyDataEnvelope.data(using: .utf8))
    let repository = HomeRepositoryImpl(provider: StubNetworkProvider<HomeService>(stubData: data))

    await #expect(throws: AuthError.backendError("홈 데이터를 불러오지 못했습니다")) {
      _ = try await repository.fetchHome()
    }
  }

  @Test func fetchHome_네트워크_에러_시_에러를_전파한다() async throws {
    let repository = HomeRepositoryImpl(provider: ThrowingStubNetworkProvider<HomeService>())

    await #expect(throws: (any Error).self) {
      _ = try await repository.fetchHome()
    }
  }
}
