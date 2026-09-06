//
//  SearchRequestMappingTests.swift
//  SearchDataTests
//

import Testing

@testable import SearchData

import APIEndpoint
import NetworkHeader

struct SearchRequestMappingTests {
  @Test func battles_요청은_GET_이며_경로가_api_v1_search_battles_이다() throws {
    let request = try SearchService.battles(category: nil, sort: nil, offset: nil, size: nil).asURLRequest()

    #expect(request.url?.path == "/api/v1/search/battles")
    #expect(request.httpMethod == "GET")
  }

  @Test func battles_요청은_모든_파라미터가_nil이면_쿼리가_없다() throws {
    let request = try SearchService.battles(category: nil, sort: nil, offset: nil, size: nil).asURLRequest()

    #expect(request.url?.query == nil)
  }

  @Test func battles_요청은_category_sort가_빈문자열이면_쿼리에서_제외한다() throws {
    let request = try SearchService.battles(category: "", sort: "", offset: nil, size: nil).asURLRequest()

    #expect(request.url?.query == nil)
  }

  @Test func battles_요청은_category_sort가_있으면_쿼리에_포함한다() throws {
    let request = try SearchService.battles(category: "love", sort: "popular", offset: nil, size: nil).asURLRequest()

    let query = try #require(request.url?.query)
    #expect(query.contains("category=love"))
    #expect(query.contains("sort=popular"))
  }

  @Test func battles_요청은_offset_size만_있어도_쿼리에_포함한다() throws {
    let request = try SearchService.battles(category: nil, sort: nil, offset: 5, size: 10).asURLRequest()

    let query = try #require(request.url?.query)
    #expect(query.contains("offset=5"))
    #expect(query.contains("size=10"))
    #expect(!query.contains("category"))
    #expect(!query.contains("sort"))
  }

  @Test func battles_요청은_모든_파라미터가_있으면_쿼리에_모두_포함한다() throws {
    let request = try SearchService.battles(category: "love", sort: "popular", offset: 0, size: 20).asURLRequest()

    let query = try #require(request.url?.query)
    #expect(query.contains("category=love"))
    #expect(query.contains("sort=popular"))
    #expect(query.contains("offset=0"))
    #expect(query.contains("size=20"))
  }

  @Test func battles_요청은_httpBody가_없다() throws {
    let request = try SearchService.battles(category: "love", sort: "popular", offset: 0, size: 20).asURLRequest()

    #expect(request.httpBody == nil)
  }

  @Test func battles_요청은_baseHeader_를_포함한다() throws {
    let request = try SearchService.battles(category: nil, sort: nil, offset: nil, size: nil).asURLRequest()

    #expect(request.value(forHTTPHeaderField: "Content-Type") != nil)
    #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer") == true)
  }
}
