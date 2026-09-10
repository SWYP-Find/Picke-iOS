//
//  PickeEmptyResponse.swift
//  PickeNetworkInterface
//

import Foundation

import Alamofire

/// 본문(payload)이 없는 응답. 성공만 받으면 되는 요청(POST/DELETE 등)의
public struct PickeEmptyResponse: Decodable, Sendable, EmptyResponse {
  public init() {}

  /// 바디가 `{}` 가 아니어도(빈 배열·빈 문자열 등) 실패하지 않도록 키 컨테이너를 열지 않는다.
  public init(from _: any Decoder) {}

  public static func emptyValue() -> PickeEmptyResponse {
    PickeEmptyResponse()
  }
}
