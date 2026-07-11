//
//  WebInterface.swift
//  WebInterface
//
//  Web 피쳐의 public 계약(route/input model + delegate). 구현(WebReducer/WebView)은 Web 타깃에 유지한다.
//  다른 피쳐(Auth/Profile)는 이 Interface 에만 의존하는 것을 목표로 한다. (문서 3~4단계)
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
