//
//  KeyValueStorageKey.swift
//  PickeStorageInterface
//
//  Created by Picke on 10/11/26.
//

public struct KeyValueStorageKey<Value: Sendable>: Hashable, Sendable {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
}
