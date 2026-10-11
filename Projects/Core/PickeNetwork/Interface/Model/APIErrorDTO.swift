//
//  APIErrorDTO.swift
//  PickeNetworkInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

/// 서버 공통 에러 응답 — `"error": { "code": ..., "message": ... }`.
public struct APIErrorDTO: Decodable, Equatable {
  public let code: String
  public let message: String

  public init(
    code: String,
    message: String
  ) {
    self.code = code
    self.message = message
  }
}
