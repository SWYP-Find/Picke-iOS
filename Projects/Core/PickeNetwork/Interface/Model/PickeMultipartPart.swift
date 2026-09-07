//
//  PickeMultipartPart.swift
//  PickeNetworkInterface
//

import Foundation

/// 멀티파트 바디의 한 조각. (파일 또는 폼 필드)
public struct PickeMultipartPart: Sendable {
  /// 파트 바이트의 출처
  public enum Source: Sendable {
    /// 메모리 바이트
    case data(Data)
    /// 파일 URL
    case file(URL)
  }

  /// 폼 필드 이름
  public let name: String
  /// 파트 바이트
  public let source: Source
  /// 파일 이름 (파일 파트일 때)
  public let fileName: String?
  /// MIME 타입 (예: "image/jpeg")
  public let mimeType: String?

  public init(
    name: String,
    source: Source,
    fileName: String? = nil,
    mimeType: String? = nil
  ) {
    self.name = name
    self.source = source
    self.fileName = fileName
    self.mimeType = mimeType
  }
}
