//
//  StorageAssembly.swift
//  CoreAssembly
//

import PickeStorage
import PickeStorageInterface

import Dependencies

public enum StorageAssembly {
  /// 앱 전역이 공유하는 Keychain 기반 보안 저장소를 내놓는다.
  public static func secureStorage() -> any SecureStorage {
    StorageFactory.secureStorage
  }

  public static func sharedValueStorage() -> any SharedValueStorage {
    StorageFactory.sharedValueStorage
  }

  public static func register(into values: inout DependencyValues) {
    StorageFactory.register(into: &values)
  }
}
