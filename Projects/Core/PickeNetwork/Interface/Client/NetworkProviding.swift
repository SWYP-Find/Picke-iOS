//
//  NetworkProviding.swift
//  PickeNetwork
//

import Foundation


/// Moya `Response` 를 대체하는 경량 응답 래퍼(디코딩 전 원시 응답).
/// `requestResponse` 사용처(로그아웃/탈퇴)가 `statusCode`/`data` 만 참조하므로 그 둘만 담는다.
public struct PickeResponse: Sendable {
  public let statusCode: Int
  public let data: Data

  public init(statusCode: Int, data: Data) {
    self.statusCode = statusCode
    self.data = data
  }
}

/// feature Service(`PickeTargetType`) 단위의 네트워크 요청 실행 추상.
public protocol NetworkProviding<Target> {
  associatedtype Target: PickeTargetType

  /// 응답을 `Decodable` 로 디코딩해 반환.
  func request<D: Decodable & Sendable>(_ target: Target) async throws -> D

  /// 원시 응답 반환(디코딩 전).
  func requestResponse(_ target: Target) async throws -> PickeResponse
}
