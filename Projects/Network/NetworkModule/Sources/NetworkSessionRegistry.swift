//
//  NetworkSessionRegistry.swift
//  NetworkModule
//

import Alamofire
import Foundation

/// NetworkModule 이 인증 구현체를 직접 알지 않도록 세션 조립 결과만 주입받는다.
public final class NetworkSessionRegistry: @unchecked Sendable {
  public static let shared = NetworkSessionRegistry()

  private let lock = NSLock()
  private var configuredAuthorizedSession: Session?
  private var configuredPlainSession: Session?

  private init() {}

  public func configure(
    authorizedSession: Session,
    plainSession: Session
  ) {
    lock.withLock {
      configuredAuthorizedSession = authorizedSession
      configuredPlainSession = plainSession
    }
  }

  func authorizedSession() -> Session {
    lock.withLock {
      configuredAuthorizedSession
    } ?? SessionFactory.plain()
  }

  func plainSession() -> Session {
    lock.withLock {
      configuredPlainSession
    } ?? SessionFactory.plain()
  }
}
