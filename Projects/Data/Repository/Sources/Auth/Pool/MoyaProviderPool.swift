//
//  MoyaProviderPool.swift
//  Repository
//
//  Created by Wonji Suh on 5/14/26.
//

import AsyncMoya
import Foundation
import Moya

/// MoyaProvider 재사용 풀 (메모리 최적화)
public final class MoyaProviderPool: @unchecked Sendable {
  public static let shared = MoyaProviderPool()

  private var defaultProviders: [String: Any] = [:]
  private var authorizedProviders: [String: Any] = [:]
  private let queue = DispatchQueue(label: "picke.moya.provider.pool", attributes: .concurrent)

  private init() {}

  /// 기본 Provider 반환 (재사용)
  public func defaultProvider<T: TargetType>(for targetType: T.Type) -> MoyaProvider<T> {
    let key = String(describing: targetType)

    return queue.sync(flags: .barrier) {
      if let existing = defaultProviders[key] as? MoyaProvider<T> {
        return existing
      }
      let new = MoyaProvider<T>.default
      defaultProviders[key] = new
      return new
    }
  }

  /// 인증된 Provider 반환 (재사용)
  public func authorizedProvider<T: TargetType>(for targetType: T.Type) -> MoyaProvider<T> {
    let key = String(describing: targetType)

    return queue.sync(flags: .barrier) {
      if let existing = authorizedProviders[key] as? MoyaProvider<T> {
        return existing
      }
      let new = MoyaProvider<T>.authorized
      authorizedProviders[key] = new
      return new
    }
  }

  /// 풀 정리 (메모리 경고 시 호출)
  func clearPool() {
    queue.async(flags: .barrier) {
      self.defaultProviders.removeAll()
      self.authorizedProviders.removeAll()
    }
  }
}
