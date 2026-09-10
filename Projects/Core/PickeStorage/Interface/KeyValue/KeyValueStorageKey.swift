//
//  KeyValueStorageKey.swift
//  PickeStorageInterface
//

public struct KeyValueStorageKey<Value: Sendable>: Hashable, Sendable {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
}
