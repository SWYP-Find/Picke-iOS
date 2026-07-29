//
//  WebInterface.swift
//  WebInterface
//

import Foundation

/// Web 화면 진입 입력값. (WebReducer.State 구성에 사용)
public struct WebRoute: Equatable, Sendable {
  public let url: String

  public init(url: String) {
    self.url = url
  }
}

/// Web 화면이 상위 coordinator 로 올려보내는 delegate 계약.
public enum WebDelegate: Equatable, Sendable {
  /// 루트로 복귀 요청.
  case backToRoot
}

public enum WebInterface {}
