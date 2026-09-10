//
//  ResponseError.swift
//  PickeNetworkInterface
//

import Foundation

/// 서버가 명시적으로 내려준 에러 응답.
public struct ResponseError: Error, Sendable, Equatable {
  /// HTTP status
  public let httpStatus: Int
  /// 서버 에러 코드 (예: "BATTLE_NOT_FOUND"). 없을 수 있다.
  public let code: String?
  /// 서버 에러 메시지
  public let message: String?

  public init(
    httpStatus: Int,
    code: String? = nil,
    message: String? = nil
  ) {
    self.httpStatus = httpStatus
    self.code = code
    self.message = message
  }

  /// 인증 실패 — 토큰 갱신/재로그인 분기용.
  public var isUnauthorized: Bool {
    httpStatus == 401
  }

  /// 5xx 인프라성 에러 여부
  public var isServerError: Bool {
    (500 ..< 600).contains(httpStatus)
  }
}
