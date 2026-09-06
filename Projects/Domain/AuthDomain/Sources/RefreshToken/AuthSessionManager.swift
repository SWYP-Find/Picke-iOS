//
//  AuthSessionManager.swift
//  AuthDomain
//
//  Created by Wonji Suh on 5/14/26.
//

import Alamofire
import AuthDomainInterface
import Foundation
import PickeStorageInterface
import UIKit
import WeaveDI

public final class AuthSessionManager {
  public static let shared = AuthSessionManager()

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

  public func updateCredential(with tokens: AuthTokens) {
    credential = AccessTokenCredential.make(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken
    )
  }

  public func clear() {
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
