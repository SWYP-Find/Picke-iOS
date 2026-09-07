//
//  PickeHTTPResponse.swift
//  PickeNetworkInterface
//

import Foundation

/// 상태 코드와 원시 바디를 호출부가 직접 해석해야 할 때 쓰는 응답 래퍼(디코딩 전).
public struct PickeHTTPResponse: Sendable, Equatable {
  public let statusCode: Int
  public let data: Data

  public init(statusCode: Int, data: Data) {
    self.statusCode = statusCode
    self.data = data
  }
}
