//
//  PickeAuthTesting.swift
//  PickeAuthTesting
//

import Foundation

import PickeAuthInterface

/// 인증 상태만 메모리에 들고 있는 테스트 더블.
/// 저장소·네트워크 세션을 건드리지 않아 Repository 테스트에서 그대로 주입할 수 있다.
public actor StubAuthService: AuthService {
  private var accessToken: String?
  private var storedRefreshToken: String?

  public init(accessToken: String? = nil, refreshToken: String? = nil) {
    self.accessToken = accessToken
    storedRefreshToken = refreshToken
  }

  public var isLoggedIn: Bool {
    accessToken != nil && storedRefreshToken != nil
  }

  public var refreshToken: String? {
    storedRefreshToken
  }

  public func signIn(accessToken: String, refreshToken: String) async {
    self.accessToken = accessToken
    storedRefreshToken = refreshToken
  }

  public func signOut() async {
    accessToken = nil
    storedRefreshToken = nil
  }
}
