//
//  StorageFactory.swift
//  PickeStorage
//

import PickeCoreLogger

import PickeStorageInterface

import Dependencies
import SQLiteData

public enum StorageFactory {
  private static let database = prepareDatabase()

  static func prepareDatabase(
    primary: () throws -> any DatabaseWriter = { try SQLiteData.defaultDatabase() },
    fallback: () throws -> any DatabaseWriter = { try DatabaseQueue() },
    migrate: (any DatabaseWriter) throws -> Void = AppDatabaseMigrator.migrate
  ) -> (any DatabaseWriter)? {
    do {
      let database = try primary()
      try migrate(database)
      return database
    } catch {
      PickeLogger.error("앱 데이터베이스 준비 실패: \(String(describing: error))", category: .storage)
    }

    do {
      let database = try fallback()
      try migrate(database)
      return database
    } catch {
      PickeLogger.error("메모리 데이터베이스 준비 실패: \(String(describing: error))", category: .storage)
      return nil
    }
  }

  public static var secureStorage: any SecureStorage {
    KeychainStorage()
  }

  public static var sharedValueStorage: any SharedValueStorage {
    guard let database else {
      return VolatileSharedValueStorage()
    }
    return SQLiteSharedValueStorage(database: database)
  }

  public static var keyValueStorage: any KeyValueStorage {
    UserDefaultStore()
  }

  public static var databaseWriter: (any DatabaseWriter)? {
    database
  }

  public static func register(into values: inout DependencyValues) {
    if let database {
      values.defaultDatabase = database
      values.appDatabase = database
    }
    values.sharedValueStorage = sharedValueStorage
    values.keyValueStorage = keyValueStorage
  }
}
