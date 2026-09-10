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

extension SharedValueStorageDependency: DependencyKey {
  public static var liveValue: any SharedValueStorage {
    StorageFactory.sharedValueStorage
  }
}

extension KeyValueStorageDependency: DependencyKey {
  public static var liveValue: any KeyValueStorage {
    StorageFactory.keyValueStorage
  }
}
