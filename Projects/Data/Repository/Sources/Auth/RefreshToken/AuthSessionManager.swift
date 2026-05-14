//
//  AuthSessionManager.swift
//  Repository
//
//  Created by Wonji Suh on 5/14/26.
//

import Alamofire
import DomainInterface
import Entity
import Foundation
import UIKit
import WeaveDI

final class AuthSessionManager {
  static let shared = AuthSessionManager()

  @Dependency(\.keychainManager) var keychainManager

  var credential: AccessTokenCredential?
  let session: Session

  private var memoryCleanupTimer: Timer?

  private init() {
    session = Session(interceptor: AuthInterceptor())
    setupInitialCredential()
    setupMemoryOptimization()
  }

  deinit {
    memoryCleanupTimer?.invalidate()
  }

  func updateCredential(with tokens: AuthTokens) {
    credential = AccessTokenCredential.make(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken
    )
  }

  func clear() {
    credential = nil
    forceMemoryCleanup()
  }

  private func setupMemoryOptimization() {
    memoryCleanupTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
      self?.performPeriodicCleanup()
    }

    NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.forceMemoryCleanup()
    }
  }

  private func performPeriodicCleanup() {
    if let credential, credential.isExpired {
      self.credential = nil
    }
  }

  private func forceMemoryCleanup() {
    credential = nil
    session.session.configuration.urlCache?.removeAllCachedResponses()
  }
}

private extension AuthSessionManager {
  func setupInitialCredential() {
    if let loaded = loadCredentialFromKeychain() {
      credential = loaded
    }
  }

  func loadCredentialFromKeychain() -> AccessTokenCredential? {
    let access = keychainManager.accessToken()
    let refresh = keychainManager.refreshToken()
    guard let access, let refresh, !access.isEmpty, !refresh.isEmpty else { return nil }
    return AccessTokenCredential.make(accessToken: access, refreshToken: refresh)
  }
}
