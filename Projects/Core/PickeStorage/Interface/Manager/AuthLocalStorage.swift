//
//  AuthLocalStorage.swift
//  PickeStorageInterface
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
