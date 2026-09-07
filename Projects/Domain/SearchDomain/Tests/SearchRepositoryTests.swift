//
//  SearchRepositoryTests.swift
//  SearchDataTests
//

import Testing

@testable import SearchData

import APIEndpoint
import BattleDomainInterface
import HomeDomainInterface

struct SearchRepositoryTests {
  @Test func searchBattles_은_정상_응답을_ExploreItemPage로_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "battleId": 1,
            "thumbnailUrl": "https://picke.dev/thumb1.png",
            "title": "제목1",
            "summary": "요약1",
            "tags": [{"tagId": 10, "name": "연애", "type": "CATEGORY"}],
            "audioDuration": 180,
            "viewCount": 42
          },
          {
            "battleId": 2,
            "thumbnailUrl": null,
            "title": null,
            "summary": null,
            "tags": null,
            "audioDuration": null,
            "viewCount": null
          }
        ],
        "nextOffset": 20,
        "hasNext": true
      },
      "error": null
    }
    """.data(using: .utf8)!

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: json)
    } operation: {
      SearchRepositoryImpl()
    }

    let page = try await repo.searchBattles(category: "연애", sort: "popular", offset: 0, size: 20)

    #expect(page.items.count == 2)
    #expect(page.nextOffset == 20)
    #expect(page.hasNext == true)

    let first = page.items[0]
    #expect(first.id == 1)
    #expect(first.category == "연애")
    #expect(first.title == "제목1")
    #expect(first.summary == "요약1")
    #expect(first.minutes == 3)
    #expect(first.viewCount == 42)
    #expect(first.imageURL == "https://picke.dev/thumb1.png")

    let second = page.items[1]
    #expect(second.id == 2)
    #expect(second.category == "")
    #expect(second.title == "")
    #expect(second.summary == "")
    #expect(second.minutes == 0)
    #expect(second.viewCount == 0)
    #expect(second.imageURL == nil)
  }

  @Test func searchBattles_은_빈_결과도_매핑한다() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [],
        "nextOffset": null,
        "hasNext": false
      },
      "error": null
    }
    """.data(using: .utf8)!

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: json)
    } operation: {
      SearchRepositoryImpl()
    }

    let page = try await repo.searchBattles(category: nil, sort: nil, offset: nil, size: nil)

    #expect(page.items.isEmpty)
    #expect(page.nextOffset == nil)
    #expect(page.hasNext == false)
  }

  @Test func searchBattles_은_data가_nil이면_backendError를_던진다() async throws {
    let json = """
    {
      "statusCode": 400,
      "data": null,
      "error": { "code": "SEARCH_400", "message": "잘못된 검색 조건입니다" }
    }
    """.data(using: .utf8)!

    let repo = withDependencies {
      $0.networkClient = StubNetworkClient(stubData: json)
    } operation: {
      SearchRepositoryImpl()
    }

    await #expect(throws: BattleError.backendError("잘못된 검색 조건입니다")) {
      try await repo.searchBattles(category: nil, sort: nil, offset: nil, size: nil)
    }
  }

  @Test func searchBattles_은_네트워크_에러를_전파한다() async throws {
    let repo = withDependencies {
      $0.networkClient = ThrowingStubNetworkClient()
    } operation: {
      SearchRepositoryImpl()
    }

    await #expect(throws: (any Error).self) {
      try await repo.searchBattles(category: nil, sort: nil, offset: nil, size: nil)
    }
  }
}
