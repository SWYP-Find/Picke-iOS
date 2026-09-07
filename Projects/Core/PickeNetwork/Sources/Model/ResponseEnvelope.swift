//
//  ResponseEnvelope.swift
//  PickeNetwork
//

import Foundation

import Alamofire
import PickeNetworkInterface

/// 서버 공통 응답 봉투.
/// ```json
/// { "statusCode": 200, "data": { ... }, "error": { "code": "...", "message": "..." } }
/// ```
/// 봉투 해석은 클라이언트가 전담한다 — 호출부(Repository)는 페이로드만 받는다.
struct ResponseEnvelope<Payload: Decodable>: Decodable {
  struct Failure: Decodable {
    let code: String?
    let message: String?
  }

  let statusCode: Int?
  let data: Payload?
  let error: Failure?
}

extension ResponseEnvelope: EmptyResponse where Payload == PickeEmptyResponse {
  /// 204 처럼 바디가 없는 성공 응답은 빈 페이로드로 채운다.
  static func emptyValue() -> ResponseEnvelope<PickeEmptyResponse> {
    ResponseEnvelope(statusCode: nil, data: PickeEmptyResponse(), error: nil)
  }
}
