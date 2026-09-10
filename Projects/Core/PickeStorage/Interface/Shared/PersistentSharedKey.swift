//
//  PersistentSharedKey.swift
//  PickeStorageInterface
//

import Foundation

import Dependencies
import Sharing

public extension SharedReaderKey {
  /// 라이브 앱에서는 조립된 영속 저장소를, 테스트·Preview 에서는 메모리 저장소를 쓴다.
  static func persistent<Value>(
    _ key: String,
    encode: @escaping @Sendable (Value) throws -> Data,
    decode: @escaping @Sendable (Data) throws -> Value,
    legacyData: @escaping @Sendable () throws -> Data? = { nil }
  ) -> Self where Self == PersistentSharedKey<Value> {
    PersistentSharedKey(
      key: key,
      encode: encode,
      decode: decode,
      legacyData: legacyData
    )
  }
}

public struct PersistentSharedKey<Value: Sendable>: SharedKey {
  public struct ID: Hashable, Sendable {
    fileprivate enum Location: Hashable, Sendable {
      case persistent(SharedValueStorageIdentifier)
      case inMemory(InMemoryStorage)
    }

    fileprivate let key: String
    fileprivate let location: Location
  }

  private enum Storage: Sendable {
    case persistent(any SharedValueStorage)
    case inMemory(InMemoryKey<Value>, InMemoryStorage)
  }

  private let key: String
  private let storage: Storage
  private let encode: @Sendable (Value) throws -> Data
  private let decode: @Sendable (Data) throws -> Value
  private let legacyData: @Sendable () throws -> Data?

  public var id: ID {
    switch storage {
    case let .persistent(storage):
      ID(key: key, location: .persistent(storage.identifier))
    case let .inMemory(_, storage):
      ID(key: key, location: .inMemory(storage))
    }
  }

  public init(
    key: String,
    encode: @escaping @Sendable (Value) throws -> Data,
    decode: @escaping @Sendable (Data) throws -> Value,
    legacyData: @escaping @Sendable () throws -> Data? = { nil }
  ) {
    @Dependency(\.context) var context

    self.key = key
    self.encode = encode
    self.decode = decode
    self.legacyData = legacyData

    switch context {
    case .live:
      @Dependency(\.sharedValueStorage) var storage
      self.storage = .persistent(storage)
    case .preview, .test:
      @Dependency(\.defaultInMemoryStorage) var storage
      let inMemoryKey: InMemoryKey<Value> = .inMemory(key)
      self.storage = .inMemory(inMemoryKey, storage)
    }
  }

  public func load(
    context: LoadContext<Value>,
    continuation: LoadContinuation<Value>
  ) {
    switch storage {
    case let .persistent(storage):
      do {
        if let data = try storage.load(forKey: key) {
          continuation.resume(returning: try decode(data))
        } else if let data = try legacyData() {
          // 기존 UserDefaults 값이 있으면 첫 조회 때 영속 저장소로 옮긴다.
          try storage.save(data, forKey: key)
          continuation.resume(returning: try decode(data))
        } else {
          continuation.resumeReturningInitialValue()
        }
      } catch {
        continuation.resume(throwing: error)
      }
    case let .inMemory(inMemoryKey, _):
      inMemoryKey.load(context: context, continuation: continuation)
    }
  }

  public func subscribe(
    context: LoadContext<Value>,
    subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    switch storage {
    case .persistent:
      // 앱 안에서 같은 key 는 Sharing 의 persistent reference 를 공유한다.
      // 이 테이블을 바꾸는 외부 writer 가 없어 별도 observation 이 필요 없다.
      SharedSubscription {}
    case let .inMemory(inMemoryKey, _):
      inMemoryKey.subscribe(context: context, subscriber: subscriber)
    }
  }

  public func save(
    _ value: Value,
    context: SaveContext,
    continuation: SaveContinuation
  ) {
    switch storage {
    case let .persistent(storage):
      do {
        try storage.save(try encode(value), forKey: key)
        continuation.resume()
      } catch {
        continuation.resume(throwing: error)
      }
    case let .inMemory(inMemoryKey, _):
      inMemoryKey.save(value, context: context, continuation: continuation)
    }
  }
}

extension PersistentSharedKey: CustomStringConvertible {
  public var description: String {
    ".persistent(\(String(reflecting: key)))"
  }
}
