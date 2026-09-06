//
//  TestSupport.swift
//  CommentDataTests
//

import Foundation

import PickeNetwork

struct StubNetworkProvider<Target: PickeTargetType>: NetworkProviding {
  let stubData: Data
  var statusCode: Int = 200

  func request<D: Decodable & Sendable>(_: Target) async throws -> D {
    try JSONDecoder().decode(D.self, from: stubData)
  }

  func requestResponse(_: Target) async throws -> PickeResponse {
    PickeResponse(statusCode: statusCode, data: stubData)
  }
}

struct ThrowingStubNetworkProvider<Target: PickeTargetType>: NetworkProviding {
  struct StubError: Error {}

  func request<D: Decodable & Sendable>(_: Target) async throws -> D {
    throw StubError()
  }

  func requestResponse(_: Target) async throws -> PickeResponse {
    throw StubError()
  }
}
