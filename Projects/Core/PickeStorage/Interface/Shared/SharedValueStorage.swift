//
//  SharedValueStorage.swift
//  PickeStorageInterface
//

import Foundation

import Dependencies

public struct SharedValueStorageIdentifier: Hashable, Sendable {
  private let rawValue: UUID

  public init() {
    rawValue = UUID()
  }
}

/// `@Shared` 값의 직렬화 결과를 보관하는 저장소 경계.
public protocol SharedValueStorage: Sendable {
  var identifier: SharedValueStorageIdentifier { get }

  func load(forKey key: String) throws -> Data?
  func save(_ data: Data, forKey key: String) throws
  func remove(forKey key: String) throws
}

public enum SharedValueStorageDependency: TestDependencyKey {
  public static let testValue: any SharedValueStorage = UnimplementedSharedValueStorage()
}

public extension DependencyValues {
  var sharedValueStorage: any SharedValueStorage {
    get { self[SharedValueStorageDependency.self] }
    set { self[SharedValueStorageDependency.self] = newValue }
  }
}

/// 저장소를 갈아끼우지 않은 채 영속 경로를 타면 알려주는 기본값.
private struct UnimplementedSharedValueStorage: SharedValueStorage {
  let identifier = SharedValueStorageIdentifier()

  func load(forKey key: String) throws -> Data? {
    throw SharedValueStorageUnavailableError(key: key)
  }

  func save(_: Data, forKey key: String) throws {
    throw SharedValueStorageUnavailableError(key: key)
  }

  func remove(forKey key: String) throws {
    throw SharedValueStorageUnavailableError(key: key)
  }
}

private struct SharedValueStorageUnavailableError: Error {
  let key: String
}
