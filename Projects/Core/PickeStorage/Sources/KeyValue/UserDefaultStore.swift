//
//  UserDefaultStore.swift
//  PickeStorage
//

import Foundation

import PickeStorageInterface

public struct UserDefaultStore: KeyValueStorage {
  private let suiteName: String?

  private var userDefaults: UserDefaults? {
    guard let suiteName else { return .standard }
    return UserDefaults(suiteName: suiteName)
  }

  public init(suiteName: String? = nil) {
    self.suiteName = suiteName
  }

  public func load<Value>(_ key: KeyValueStorageKey<Value>) -> Value? {
    userDefaults?.object(forKey: key.rawValue) as? Value
  }

  public func save<Value>(_ value: Value?, for key: KeyValueStorageKey<Value>) {
    guard let userDefaults else { return }
    guard let value else {
      userDefaults.removeObject(forKey: key.rawValue)
      return
    }
    userDefaults.set(value, forKey: key.rawValue)
  }
}
