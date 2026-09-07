//
//  PickeRequestClient.swift
//  PickeNetworkInterface
//

import Foundation

/// 네트워크 요청 진입점.
public protocol PickeRequestClient: Sendable {
  /// 요청을 보내고 호출부가 지정한 타입으로 디코딩한다.
  func send<R: PickeDataRequest, T: Decodable & Sendable>(
    _ request: R,
    as type: T.Type
  ) async throws(PickeNetworkError) -> T

  /// 요청 타입에 선언된 `Response` 로 디코딩한다.
  func send<R: PickeDataRequest>(_ request: R) async throws(PickeNetworkError) -> R.Response

  /// 상태 코드와 원시 바디를 호출부가 직접 해석해야 하는 요청에 사용한다.
  func sendResponse<R: PickeDataRequest>(_ request: R) async throws(PickeNetworkError) -> PickeHTTPResponse
}
