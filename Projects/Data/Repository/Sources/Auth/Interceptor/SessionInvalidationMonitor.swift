//
//  SessionInvalidationMonitor.swift
//  Repository
//
//  서버가 USER_404(존재하지 않는 사용자)/AUTH_401 을 반환하면 세션을 무효화하고 강제 로그아웃한다.
//  기존 Moya `SessionInvalidationPlugin` 을 Alamofire `EventMonitor` 로 이식(동작 보존).
//  기존 .refreshTokenExpired 경로를 재사용해 로그인 화면으로 전환된다.
//

import Alamofire
import Dependencies
import DomainInterface
import Foundation
import LogMacro

struct SessionInvalidationMonitor: EventMonitor {
  let queue = DispatchQueue(label: "store.picke.network.session-invalidation")

  /// 강제 로그아웃을 유발하는 서버 에러 코드.
  /// - USER_404: 존재하지 않는 사용자
  /// - AUTH_401: 인증 필요 (AuthInterceptor refresh+retry 후에도 최종 401 이면 세션 만료로 간주)
  private static let invalidSessionCodes: Set<String> = ["USER_404", "AUTH_401"]

  private struct ErrorEnvelope: Decodable {
    struct APIError: Decodable { let code: String }
    let error: APIError?
  }

  func request(
    _: DataRequest,
    didParseResponse response: DataResponse<some Sendable, AFError>
  ) {
    guard
      let data = response.data,
      let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
      let code = envelope.error?.code,
      Self.invalidSessionCodes.contains(code)
    else { return }

    Log.error("🚪 \(code) 감지 → 강제 로그아웃")
    forceLogout()
  }

  private func forceLogout() {
    @Dependency(\.keychainManager) var keychainManager
    keychainManager.clear()

    _Concurrency.Task { @MainActor in
      AuthSessionManager.shared.credential = nil
      OptimizedSessionManager.shared.credential = nil

      NotificationCenter.default.post(
        name: .refreshTokenExpired,
        object: nil,
        userInfo: ["reason": "user_not_found"]
      )
    }
  }
}
