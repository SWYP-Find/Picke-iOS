//
//  SearchBattlesQueryRequest.swift
//  APIEndpoint
//

import Foundation

public struct SearchBattlesQueryRequest: Encodable, Sendable {
  public let category: String?
  public let sort: String?
  public let offset: Int?
  public let size: Int?

  public init(
    category: String?,
    sort: String?,
    offset: Int?,
    size: Int?
  ) {
    // 빈 문자열은 쿼리에서 제외한다(기존 동작 보존).
    self.category = (category?.isEmpty == false) ? category : nil
    self.sort = (sort?.isEmpty == false) ? sort : nil
    self.offset = offset
    self.size = size
  }
}
