//
//  StorageAssembly.swift
//  CoreAssembly
//

import PickeStorage
import PickeStorageInterface

import Dependencies

public enum StorageAssembly {
  /// 앱 전역에서 공유하는 Keychain 저장소. 인증 서비스와 DI 등록이 같은 인스턴스를 본다.
  public static let keychain: any KeychainManaging = KeychainManager()

  public static func register(into values: inout DependencyValues) {
    values.keychainManager = keychain
  }
}
