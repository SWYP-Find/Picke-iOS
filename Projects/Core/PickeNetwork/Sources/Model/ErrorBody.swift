//
//  ErrorBody.swift
//  PickeNetwork
//

import Foundation

/// 서버가 실패 응답(4xx/5xx)에 담아 주는 바디.
/// 공통 봉투의 `error` 를 우선 읽고, 봉투 없이 `{ code, message }` 만 오는 응답도 함께 살린다.
struct ErrorBody: Decodable {
  struct Payload: Decodable {
    let code: String?
    let message: String?
  }

  let error: Payload?
  let code: String?
  let message: String?

  var resolvedCode: String? { error?.code ?? code }
  var resolvedMessage: String? { error?.message ?? message }
}
