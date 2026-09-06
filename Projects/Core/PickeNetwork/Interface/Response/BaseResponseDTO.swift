//
//  BaseResponseDTO.swift
//  PickeNetworkInterface
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

/// 서버 공통 응답 봉투
/// ```json
/// {
///   "statusCode": 0,
///   "data": { ... },
///   "error": { "code": "...", "message": "..." }
/// }
/// ```
public struct BaseResponseDTO<T: Decodable>: Decodable {
  public let statusCode: Int
  public let data: T?
  public let error: APIErrorDTO?

  public init(
    statusCode: Int,
    data: T?,
    error: APIErrorDTO?
  ) {
    self.statusCode = statusCode
    self.data = data
    self.error = error
  }
}
