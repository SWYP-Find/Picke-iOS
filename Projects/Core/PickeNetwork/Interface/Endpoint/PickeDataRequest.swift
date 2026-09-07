//
//  PickeDataRequest.swift
//  PickeNetworkInterface
//

import Foundation

import Alamofire

/// 일반(비-멀티파트) 요청. 엔드포인트 메타는 `PickeEndpoint`, 바디는 `parameters` 로 표현한다.
public protocol PickeDataRequest: PickeEndpoint {
  /// 디코딩될 응답 타입
  associatedtype Response: Decodable & Sendable = PickeEmptyResponse
  /// 요청 파라미터(Encodable). 쿼리 / 바디 위치는 인코더가 결정한다.
  var parameters: (any Encodable & Sendable)? { get }
  /// 파라미터 인코더 오버라이드. nil 이면 method 기준 기본(GET/DELETE 쿼리스트링, 그 외 JSON 바디).
  var parameterEncoder: ParameterEncoder? { get }
}

public extension PickeDataRequest {
  var parameters: (any Encodable & Sendable)? {
    nil
  }

  var parameterEncoder: ParameterEncoder? {
    nil
  }
}
