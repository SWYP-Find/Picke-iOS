//
//  SearchService.swift
//  Service
//

import Foundation

import API
import PickeNetwork

public enum SearchService {
  case battles(category: String?, sort: String?, offset: Int?, size: Int?)
}

extension SearchService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.search }

  public var path: String {
    switch self {
    case .battles:
      return SearchAPI.battles.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .battles:
      return .get
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .battles(category, sort, offset, size):
      return SearchBattlesQueryRequest(
        category: category,
        sort: sort,
        offset: offset,
        size: size
      )
    }
  }
}
