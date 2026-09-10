//
//  PickeUploadRequest.swift
//  PickeNetworkInterface
//

import Foundation

/// 멀티파트 업로드 요청. 엔드포인트 메타는 `PickeEndpoint`, 바디는 `parts` 로 표현한다.
public protocol PickeUploadRequest: PickeEndpoint {
  /// 디코딩될 응답 타입
  associatedtype Response: Decodable & Sendable = PickeEmptyResponse
  /// 멀티파트 바디를 구성하는 파트들
  var parts: [PickeMultipartPart] { get }
}
