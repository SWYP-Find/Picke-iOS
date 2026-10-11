//
//  AppDatabaseDependency.swift
//  PickeStorageInterface
//
//  Created by Picke on 10/11/26.
//

import Dependencies
import SQLiteData

public enum AppDatabaseDependency: TestDependencyKey {
  public static let testValue: (any DatabaseWriter)? = nil
}

public extension DependencyValues {
  var appDatabase: (any DatabaseWriter)? {
    get { self[AppDatabaseDependency.self] }
    set { self[AppDatabaseDependency.self] = newValue }
  }
}
