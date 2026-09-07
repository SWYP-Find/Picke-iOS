//
//  PickeUploadClient.swift
//  PickeNetworkInterface
//

import Foundation

/// 멀티파트 업로드 진입점.
public protocol PickeUploadClient: Sendable {
  /// 멀티파트 요청을 전송하고 디코딩된 응답을 반환한다.
  func upload<R: PickeUploadRequest>(_ request: R) async throws(PickeNetworkError) -> R.Response
}
