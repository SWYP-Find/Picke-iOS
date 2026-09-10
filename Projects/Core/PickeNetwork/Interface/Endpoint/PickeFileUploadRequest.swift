//
//  PickeFileUploadRequest.swift
//  PickeNetworkInterface
//

import Foundation

/// presigned URL 에 원본 바이트를 PUT 업로드하는 요청.
public protocol PickeFileUploadRequest: Sendable {
  /// 업로드 대상 presigned URL
  var uploadURL: URL { get }
  /// PUT 으로 실어 보낼 원본 바이트
  var body: Data { get }
  /// 업로드 바이트의 MIME 타입
  var contentType: String { get }
  /// 타임아웃(초). nil 이면 세션 기본값 사용.
  var timeoutInterval: TimeInterval? { get }
}

public extension PickeFileUploadRequest {
  var timeoutInterval: TimeInterval? {
    nil
  }
}
