//
//  SearchService.swift
//  Service
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum SearchService {
  case battles(category: String?, sort: String?, offset: Int?, size: Int?)
}

extension SearchService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .search }

  public var urlPath: String {
    switch self {
    case .battles:
      return SearchAPI.battles.description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .battles:
      return .get
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case let .battles(category, sort, offset, size):
      var query: [String: Any] = [:]
      if let category, !category.isEmpty { query["category"] = category }
      if let sort, !sort.isEmpty { query["sort"] = sort }
      if let offset { query["offset"] = offset }
      if let size { query["size"] = size }
      return query.isEmpty ? nil : query
    }
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
