//
//  PickeFileUploadClient.swift
//  PickeNetworkInterface
//

import Foundation

/// presigned URL 원본 바이트 업로드 진입점.
public protocol PickeFileUploadClient: Sendable {
  /// presigned URL 에 원본 바이트를 PUT 업로드한다.
  func upload(_ request: some PickeFileUploadRequest) async throws(PickeNetworkError)
}
