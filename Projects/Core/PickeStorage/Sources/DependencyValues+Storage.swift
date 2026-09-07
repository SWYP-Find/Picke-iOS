//
//  DependencyValues+Storage.swift
//  PickeStorage
//

import PickeStorageInterface

import Dependencies
import SQLiteData

extension AppDatabaseDependency: DependencyKey {
  public static var liveValue: (any DatabaseWriter)? {
    StorageFactory.databaseWriter
  }
}

extension KeychainManagerDependency: DependencyKey {
  public static var liveValue: KeychainManaging {
    KeychainManager()
  }
}

extension SharedValueStorageDependency: DependencyKey {
  public static var liveValue: any SharedValueStorage {
    StorageFactory.sharedValueStorage
  }
}
