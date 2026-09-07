//
//  PickeFileUploadClient.swift
//  PickeNetworkInterface
//

import Foundation

/// presigned URL 원본 바이트 업로드 진입점.
/// 앱 서버 응답 규약을 타지 않는 스토리지 직접 업로드라, 일반 요청·멀티파트와 분리한다.
public protocol PickeFileUploadClient: Sendable {
  /// presigned URL 에 원본 바이트를 PUT 업로드한다.
  /// 응답 본문은 사용하지 않으며 성공은 HTTP 2xx 로 판정한다.
  func upload(_ request: some PickeFileUploadRequest) async throws(PickeNetworkError)
}
