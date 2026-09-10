//
//  KeyValueStorage.swift
//  PickeStorageInterface
//

import Dependencies

public protocol KeyValueStorage: Sendable {
  func load<Value>(_ key: KeyValueStorageKey<Value>) -> Value?
  func save<Value>(_ value: Value?, for key: KeyValueStorageKey<Value>)
}

public enum KeyValueStorageDependency: TestDependencyKey {
  public static let testValue: any KeyValueStorage = UnimplementedKeyValueStorage()
}

public extension DependencyValues {
  var keyValueStorage: any KeyValueStorage {
    get { self[KeyValueStorageDependency.self] }
    set { self[KeyValueStorageDependency.self] = newValue }
  }
}

private struct UnimplementedKeyValueStorage: KeyValueStorage {
  func load<Value>(_: KeyValueStorageKey<Value>) -> Value? {
    nil
  }

  func save<Value>(_: Value?, for _: KeyValueStorageKey<Value>) {}
}
