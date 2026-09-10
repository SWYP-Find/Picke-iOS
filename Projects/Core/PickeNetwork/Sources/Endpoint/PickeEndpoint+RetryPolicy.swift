//
//  PickeEndpoint+RetryPolicy.swift
//  PickeNetwork
//

import Foundation

import Alamofire
import PickeNetworkInterface

/// 429(Too Many Requests)까지 포함한 재시도 대상 status 집합.
private let retryableStatusCodes = RetryPolicy.defaultRetryableHTTPStatusCodes.union([429])

extension PickeEndpoint {
  /// 요청별 재시도 정책. 횟수는 `maxRetryAttempts` 를 단일 출처로 쓴다. (send / upload 공유)
  var retryPolicy: RetryPolicy {
    RetryPolicy(
      retryLimit: UInt(max(0, maxRetryAttempts)),
      retryableHTTPStatusCodes: retryableStatusCodes
    )
  }
}

extension PickeFileUploadRequest {
  /// presigned 업로드는 엔드포인트 메타가 없어 기본 횟수를 쓴다.
  var retryPolicy: RetryPolicy {
    RetryPolicy(
      retryLimit: 3,
      retryableHTTPStatusCodes: retryableStatusCodes
    )
  }
}
