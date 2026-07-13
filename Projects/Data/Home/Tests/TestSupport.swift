//
//  TestSupport.swift
//  HomeDataTests
//

import Foundation

import NetworkHeader
import Repository

/// 고정 데이터를 그대로 디코딩해 반환하는 스텁 provider.
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

/// 항상 에러를 던지는 스텁 provider.
struct ThrowingStubNetworkProvider<Target: PickeTargetType>: NetworkProviding {
  struct StubError: Error {}

  func request<D: Decodable & Sendable>(_: Target) async throws -> D {
    throw StubError()
  }

  func requestResponse(_: Target) async throws -> PickeResponse {
    throw StubError()
  }
}
