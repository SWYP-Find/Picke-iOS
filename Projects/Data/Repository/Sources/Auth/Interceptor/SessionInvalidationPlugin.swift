//
//  SessionInvalidationPlugin.swift
//  Repository
//
//  서버가 USER_404(존재하지 않는 사용자) 를 반환하면 세션을 무효화하고 강제 로그아웃한다.
//  기존 .refreshTokenExpired 경로를 재사용해 로그인 화면으로 전환된다.
//

import Foundation

import Dependencies
import DomainInterface
import LogMacro
import Moya

final class SessionInvalidationPlugin: PluginType {
  /// 강제 로그아웃을 유발하는 서버 에러 코드.
  private static let invalidSessionCodes: Set<String> = ["USER_404"]

  private struct ErrorEnvelope: Decodable {
    struct APIError: Decodable { let code: String }
    let error: APIError?
  }

  func didReceive(_ result: Result<Response, MoyaError>, target _: TargetType) {
    let response: Response? = switch result {
    case let .success(value):
      value
    case let .failure(error):
      error.response
    }

    guard
      let data = response?.data,
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
