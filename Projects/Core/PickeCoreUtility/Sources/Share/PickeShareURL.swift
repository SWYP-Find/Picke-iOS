//
//  PickeShareURL.swift
//  Entity
//

import Foundation

/// 공유용 웹 랜딩 링크 빌더.
/// 서버 `shareUrl` 이 빈 값이거나 무관한 도메인(pique.app 등)으로 내려오는 사고가 있어,
/// picke.store 링크만 신뢰하고 그 외에는 검증된 랜딩 경로로 대체한다.
public enum PickeShareURL {
  private static let trustedHost = "picke.store"

  /// 배틀 공유 랜딩 링크 — 웹 랜딩이 실존하는 경로는 단수형 `/battle/{id}` 다 (`/battles/{id}` 는 403).
  public static func battle(id: Int, serverShareUrl: String? = nil) -> String {
    if let serverShareUrl, isTrusted(serverShareUrl) {
      return serverShareUrl
    }
    return "https://\(trustedHost)/battle/\(id)"
  }

  /// picke.store(서브도메인 포함) 링크만 신뢰.
  private static func isTrusted(_ urlString: String) -> Bool {
    guard let host = URLComponents(string: urlString)?.host?.lowercased() else { return false }
    return host == trustedHost || host.hasSuffix(".\(trustedHost)")
  }
}
