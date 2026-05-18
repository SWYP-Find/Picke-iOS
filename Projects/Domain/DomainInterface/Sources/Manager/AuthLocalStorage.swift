//
//  AuthLocalStorage.swift
//  DomainInterface
//
//  Apple OAuth 가 응답으로 내려준 authorizationCode 와 identityToken 을
//  로컬에 보관해두는 UserDefaults wrapper. Keychain 과 달리 단순 캐시 용도.
//

import Foundation

public enum AuthLocalStorage {
  private static let authCodeKey = "picke.auth.authCode"
  private static let idTokenKey = "picke.auth.idToken"

  public static var authCode: String? {
    get { UserDefaults.standard.string(forKey: authCodeKey) }
    set { UserDefaults.standard.set(newValue, forKey: authCodeKey) }
  }

  public static var idToken: String? {
    get { UserDefaults.standard.string(forKey: idTokenKey) }
    set { UserDefaults.standard.set(newValue, forKey: idTokenKey) }
  }

  public static func clear() {
    UserDefaults.standard.removeObject(forKey: authCodeKey)
    UserDefaults.standard.removeObject(forKey: idTokenKey)
  }
}
